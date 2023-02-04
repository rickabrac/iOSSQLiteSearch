//
//  SearchViewModel.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation
import SQLite3

class SearchViewModel: Model {
	var db: OpaquePointer? = nil
	var result = [Item]()
	var catalog: Catalog? = nil
	var observer: Observer?
	var prevSearch = ""
	var sqliteDBFileName: String = ""
	var dispatchQueue: SynchronousDispatchQueue = DispatchQueue.global(qos: .background)
	var isSearchFieldHidden = false
	private var _state: CatalogState = .empty
	private var _progress: Float = 0.0
	private let mutex = NSLock()
	private var latency: Int64 = 0
	private var resultRows: Int64 = 0
	
	init(
		sqliteDBFileName: String = "",                                               // sqlite database file name
//		catalogURI: String = "http://tyler.org/iOSSportSearch/catalog.csv",          // sporting goods catalog
		catalogURI: String = "http://tyler.org/iOSSportSearch/test.csv",             // test sporting goods catalog
		aliasesURI: String = "http://tyler.org/iOSSportSearch/aliases.csv",          // word and phrase aliases
		titleHintsURI: String = "http://tyler.org/iOSSportSearch/titlehints.csv",    // used to strip color/size information from title
		brandHintsURI: String = "http://tyler.org/iOSSportSearch/brandhints.csv",    // brand name overrides and aliases
		brandMarksURI: String = "http://tyler.org/iOSSportSearch/brandmarks.csv"     // brand-specific product names
	) {
		if sqliteDBFileName != "TestCatalog.sqlite" {
			self.catalog = Catalog( catalogURI,
				aliasesURI: aliasesURI,
				titleHintsURI: titleHintsURI,
				brandHintsURI: brandHintsURI,
				brandMarksURI: brandMarksURI
			)
		}
		if sqliteDBFileName != "" {
			let dbPath = FileManager.default
				.urls(for: .documentDirectory, in: .userDomainMask)
				.first!.appendingPathComponent(sqliteDBFileName).path
			if FileManager.default.fileExists(atPath: dbPath) {
				// cached db from previous run allows us to launch immediately
				self.db = SQLiteQuery.dbOpen(path: dbPath)
			}
			self.sqliteDBFileName = sqliteDBFileName
			let importURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
				.first!.appendingPathComponent("import.sqlite")
			do {
				try FileManager.default.removeItem(at: importURL)
			} catch {
				// no-op
			}
		}
	}
	
	var progress: Float {
		set {
			_progress = newValue
		}
		get {
			if catalog == nil {
				return _progress
			}
			guard let catalog = catalog else {
				fatalError("\(name(self)).updateCatalog: failed to unwrap catalog")
			}
			return catalog.progress
		}
	}
	
	var numberOfRows: Int {
		return state == .searching ? 0 : result.count
	}
	
	var state: CatalogState {
		get {
			guard let catalog = catalog else {
				return _state
			}
			return catalog.state
		}
		set {
			_state = newValue
			observer?.modelDidUpdate()
		}
	}
	
	func loadCatalog() {
		guard let catalog = catalog else {
			fatalError("\(name(self)).updateCatalog: failed to unwrap catalog")
		}
		catalog.observer = observer
		if self.db != nil {
			sqliteDBFileName = "import.sqlite"
		}
		catalog.load(into: sqliteDBFileName)
	}
	
	func updateCatalog() -> Bool {
		if catalog == nil {
			return false
		}
		guard let catalog = catalog else {
			fatalError("\(name(self)).updateCatalog: failed to unwrap catalog")
		}
		if sqliteDBFileName != "import.sqlite" || catalog.state != .ready {
			return false
		}
		mutex.lock()
		sqliteDBFileName = "catalog.sqlite"
		var error: Int32
		error = sqlite3_close(self.db)
		while error == SQLITE_BUSY {
			sleep(1)
			error = sqlite3_close(self.db)
		}
		if error != SQLITE_OK {
			fatalError("\(name(self)).modelDidUpdate: failed to close db (\(error))")
		}
		error = sqlite3_close(catalog.db)
		while error == SQLITE_BUSY {
			error = sqlite3_close(catalog.db)
		}
		if error != SQLITE_OK {
			fatalError("\(name(self)).modelDidUpdate: failed to close db (\(error))")
		}
		let importURL = FileManager.default
			.urls(for: .documentDirectory, in: .userDomainMask)
			.first!.appendingPathComponent("import.sqlite")
		let dbURL = FileManager.default
			.urls(for: .documentDirectory, in: .userDomainMask)
			.first!.appendingPathComponent("catalog.sqlite")
		do {
			try FileManager.default.removeItem(at: dbURL)
		} catch {
			// n.a.
		}
		do {
			try FileManager.default.copyItem(at: importURL, to: dbURL)
		} catch {
			fatalError("\(name(self)).modelDidUpdate: failed to update database")
		}
		let dbPath = FileManager.default
			.urls(for: .documentDirectory, in: .userDomainMask)
			.first!.appendingPathComponent(sqliteDBFileName).path
		self.db = SQLiteQuery.dbOpen(path: dbPath)
		result = []
		self.catalog = nil
		mutex.unlock()
		if prevSearch.count > 0 {
			self.search(prevSearch)
		}
		return true
	}
	
	func search(_ input: String ) {
		if input == "" {
			return
		}
		if self.db == nil {
			guard let catalog = catalog else {
				fatalError("\(name(self)).updateCatalog: failed to unwrap catalog")
			}
			self.db = catalog.db
		}
		guard let db = self.db else {
			fatalError("\(name(self)).search: failed to unwrap catalog.db")
		}
		dispatchQueue.execute {
			if self.mutex.try() == false {
				return
			}
			self.state = .searching
			self.result = []
			self.observer?.modelDidUpdate()
			self.prevSearch = input
			var trailingWordMatch = false  // if true, perform exact match on trailing term
			if input.last == " ", input.first != "#" {
				trailingWordMatch = true
			}
			var stripped = input
				.trimmingCharacters(in: .whitespaces)
				.uppercased()
			if stripped == "*" {
				stripped = ""
			}
//			if stripped == "" { // comment out to allow empty search
//				self.result = []
//				self.observer?.modelDidUpdate()
//				self.state = .ready
//				return
//			}
			var strings = [String]()
			var brand = ""
			var serial = ""
			var sql: String
			var selectItem: SQLiteQuery
			var listBrands = false
			if stripped == "/" {
				sql = "select brand from item join brand on brandId = brand.id group by brandId order by brand"
				selectItem = SQLiteQuery(db, sql)
				listBrands = true
			} else {
				sql = "select brand, title, price, serial from item" +
					" join title on titleId = title.id" +
					" join brand on brandId = brand.id"
				var count = 0
				let splitInput = stripped.split(separator: " ")
				var mensSearch = ""
				var trailingSearchWord = ""
				for _string in splitInput {
					// disambiguate common search terms that include apostrophes
					var string = String(_string)
					if string.contains("\\") {
						string = string.replacingOccurrences(of: "\\", with: " ")
					}
					if string == "VNECK" {
						string = "V-NECK"
					}
					// filter out results for women if search terms includes "men's", "mens", or "men"
					if string == "MEN" || string == "MENS" || string == "MEN’S" || string == "MENS’" {
						mensSearch = "MEN’S %"
						count += 1
						continue
					}
					else if string == "WOMEN" || string == "WOMENS" || string == "WOMENS’" {
						string = "WOMEN’S"
					} else if string == "BOY" || string == "BOYS" || string == "BOYS’" {
						string = "BOY’S"
					} else if string == "GIRL" || string == "GIRLS" || string == "GIRLS’" {
						string = "GIRL’S"
					}
					count += 1
					if trailingWordMatch, count == splitInput.count {
						if string.first == "/" {
							var _brand = string
							_brand.removeFirst()
							brand = "\(_brand)"
							continue
						}
						trailingSearchWord = string
						continue
					} else {
						if string.first == "/" {
							var _brand = string
							_brand.removeFirst()
							brand = "\(_brand)%"
							continue
						} else if string.first == "#" {
							var _serial = string
							_serial.removeFirst()
							serial = "%\(_serial)%"
							continue
						}
						strings.append("%\(string)%")
					}
				}
				var index: Int32 = 1
				var whereClause = ""
				for _ in strings {
					if index > 1 {
						whereClause += " and"
					}
					index += 1
					whereClause += " title like ?"
				}
				if brand != "" {
					let brandClause = (trailingWordMatch ? "= " : "like ") + "?"
					if strings.count > 0 {
						whereClause += " and brand \(brandClause)"
					} else {
						whereClause += " brand \(brandClause)"
					}
				}
				if mensSearch != "" {
					if index > 1 {
						whereClause += " and"
					}
					whereClause += " (title like ? or title like ?)"
					strings.append(mensSearch)
					strings.append(" \(mensSearch)")
					index += 2
				}
				if trailingSearchWord != "" {
					if index > 1 {
						whereClause += " and"
					}
					whereClause += " (title like ? or title like ? or title like ?)"
					strings.append("\(trailingSearchWord) %")
					strings.append("% \(trailingSearchWord) %")
					strings.append("% \(trailingSearchWord)")
					index += 3
				}
				if serial.count > 0 {
					if strings.count > 0 || brand != "" {
						whereClause += " and serial like ?"
					} else {
						whereClause += " serial like ?"
					}
				}
				if whereClause.count > 0 {
					sql += " where" + whereClause
				}
				sql += " group by brandId, titleId, price order by title, brand, price"
				selectItem = SQLiteQuery(db, sql)
				index = 1
				for string in strings  {
					selectItem.bindString(index, string
						.replacingOccurrences(of: "”", with: "\'")
						.replacingOccurrences(of: "’", with: "\'"))
					index += 1
				}
				if brand.count > 0 {
					selectItem.bindString(index, brand)
					index += 1
				}
				if serial.count > 0 {
					selectItem.bindString(index, serial)
				}
			}
			let start = currentTimeMillis()
			var titleBrands: [String: Set<String>] = [:]
			var tempResult = [Item]()
			print("\(selectItem.sql)")
			if listBrands {
				while selectItem.execute() {
					let brand = selectItem.getString(colIdx: 0)
					if brand == "?" {
						continue
					}
					let item = Item(serial: "", brand: brand, title: "", price: "")
					self.result.append(item)
				}
				self.state = .ready
				self.observer?.modelDidUpdate()
				print("\(currentTimeMillis() - start) ms (\(self.result.count) records)")
				self.mutex.unlock()
				return
			}
			self.resultRows = 0
			while selectItem.execute() {
				let brand = selectItem.getString(colIdx: 0)
				let title = selectItem.getString(colIdx: 1)
				if titleBrands[title] == nil {
					titleBrands[title] = Set<String>()
				}
				if brand == "" {
					titleBrands[title]?.insert(brand)
				}
				let price = selectItem.getCurrency(colIdx: 2)
				let item = Item(serial: serial != "" ? serial : "", brand: brand, title: title, price: price)
				tempResult.append(item)
				self.resultRows += 1
			}
			if selectItem.bound {
				selectItem.finalize()
			}
			var prevItem: Item? = nil
			for item in tempResult {
				if item.brand == prevItem?.brand, item.strippedTitle() == prevItem?.strippedTitle(), item.price == prevItem?.price {
					continue
				}
				if item.title == prevItem?.title {
					if item.price != prevItem?.price {
						prevItem?.price = ""
						continue
					}
					if item.brand != prevItem?.brand {
						prevItem?.price = ""
					}
					continue
				}
				prevItem = item
				guard let titleBrand = titleBrands[item.title] else {
					fatalError("\(name(self)).search: failed to unwrap titleBrand")
				}
				if titleBrand.count > 1  {
					item.brand = ""
					item.price = ""
				}
				self.result.append(item)
				prevItem = item
			}
			tempResult = self.result
			self.result = []
			prevItem = nil
			for item in tempResult {
				let strippedTitle = item.strippedTitle()
				if item.brand != prevItem?.brand, strippedTitle == prevItem?.strippedTitle() {
					prevItem?.brand = ""
					prevItem?.title = strippedTitle
					prevItem?.price = ""
					continue
				}
				prevItem = item
				self.result.append(item)
			}
			self.state = .ready
			self.observer?.modelDidUpdate()
			self.latency = currentTimeMillis() - start;
			print("\(self.latency) ms (\(self.resultRows) records)")
			self.mutex.unlock()
		}
	}
	
	func getLoadingState() -> String {
		switch state {
		case .fetching:
			return "   Fetching..."
		case .loading:
			return "   Loading..."
		case .indexing:
			return "   Indexing..."
		default:
			return ""
		}
	}
	
	func getLoadingDetail() -> String {
		let percent = Int(100 * progress)
		if state == .indexing {
			return ""
		}
		if state == .loading, let catalog = catalog {
			return "\(catalog.loopIndex) / \(catalog.loopCount) records (\(percent)%)"
		}
		return "\(percent)%"
	}
	
	func leftText(forRowAt indexPath: IndexPath) -> String {
		if indexPath.row > result.count - 1 {
			return ""
		}
		let item = result[indexPath.row]
		if item.title == "" {
			return ""
		}
		return "\(item.title)"
	}
	
	func centerText(forRowAt indexPath: IndexPath) -> String {
		if indexPath.row > result.count - 1 {
			return ""
		}
		let item = result[indexPath.row]
		if item.brand == "" {
			return ""
		}
		if item.brand == "?" {
			return ""
		}
		if item.title == "" {
			return item.brand
		}
		return ""
	}
	
	func rightText(forRowAt indexPath: IndexPath) -> String {
		if indexPath.row > result.count - 1 {
			return ""
		}
		return result[indexPath.row].price
	}
	
	func showDisclosureIndicator(forRowAt indexPath: IndexPath) -> Bool {
		if indexPath.row > result.count - 1 {
			return false
		}
		let title = result[indexPath.row].title
		if title == "" {
			return false
		}
		return result[indexPath.row].price == "" ? true : false
	}
	
	func getItemViewModel(forRowAt indexPath: IndexPath) -> DetailViewModel {
		guard let db = self.db else {
			fatalError("\(name(self)).getItemViewModel: failed to unwrap catalog.db")
		}
		return DetailViewModel(db: db)
	}
	
	func getItem(forRowAt indexPath: IndexPath) -> Item {
		if indexPath.row > result.count - 1 {
			return Item(serial: "", brand: "", title: "", price: "")
		}
		return result[indexPath.row]
	}
	
	var latencyText: String {
		if self.state == .searching || latency == 0 {
			return ""
		}
		return "\(latency) ms"
	}
	
	var resultRowsText: String {
		if self.state == .searching || resultRows == 0 {
			return ""
		}
		return "\(resultRows) rows"
	}
}
