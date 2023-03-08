//
//  Catalog.swift
//  SportSearch
//  Created by Rick Tyler
//
//  Fetches sporting goods catalog from cloud and inserts into SQLite.
//

import Foundation
import SQLite3
import UIKit

enum CatalogState {
	case empty        // init state
	case failed       // failed download
	case fetching     // fetching data
	case loading      // sqlite loading
	case indexing     // sqlite indexing
	case ready        // ready
}

class Catalog: Model {
	
	internal var observer: Observer?
	var sqliteDBFileName: String = ""
	var db: OpaquePointer? = nil
	var sourceBytes: UInt = 0
	var bytesScanned: UInt = 0
	var loopIndex = 0
	var loopCount: Int = 0
	private var dbPath: String = ""
	private let catalogURI: String
	private let catalogFileName: String
	private var catalogCSV: TextFile? = nil
	private var aliasesURI: String? = nil
	private var titleHintsURI: String? = nil
	private var brandHintsURI: String? = nil
	private var brandMarksURI: String? = nil
	private var maxAliasWords = 0
	private var maxBrandWords = 0
	private var maxProductWords = 0
	private let modelDidUpdateInterval = 1000
	private var inputTitles = [String]()
	private var titleHints = Set<String>()
	private var notBrands = Set<String>()
	private var brandNames = Set<String>()
	private var brandAlias: [String: String]  = [:]
	private var brandMark: [String: String]  = [:]
	private var alias: [String: String]  = [:]
	private var itemKeys = Set<String>()
	private var itemIds = [String: Int64]()
	private var brandIds = [String: Int64]()
	private var titleIds = [String: Int64]()
	private var colorIds = [String: Int64]()
	private var sizeIds = [String: Int64]()
	private var brandItems = [String: Set<String>]()    // [brand : set of distinct Items]
	private var _state: CatalogState
	
	required init(_ catalogURI: String, aliasesURI: String, titleHintsURI: String, brandHintsURI: String, brandMarksURI: String) {
		self._state = .empty
		self.catalogURI = catalogURI
		self.catalogFileName = String(catalogURI.split(separator: "/").last!)
		self.aliasesURI = aliasesURI
		self.titleHintsURI = titleHintsURI
		self.brandHintsURI = brandHintsURI
		self.brandMarksURI = brandMarksURI
	}
	
	var state: CatalogState {
		get {
			return _state
		}
		set {
			_state = newValue
			observer?.modelDidUpdate()
		}
	}
	
	var progress: Float {
		switch state {
		case .empty, .fetching:
			return 0.0
		case .loading:
			return loopCount == 0 ? 0.5 : Float(loopIndex) / Float(loopCount)
		case .indexing, .ready:
			return 1.0
		case .failed:
			return 0.0
		}
	}

	var isInMemoryDB: Bool {
		return sqliteDBFileName == ":memory:"
	}
	
	func load(into sqliteDBFileName: String) {
		self.state = .fetching
		self.sqliteDBFileName = sqliteDBFileName
		var failed = false
		let file = TextFile(catalogFileName)
		file.fetch(self.catalogURI) { (success, error) in
			if success == false {
				print("\(name(self)).load: TextFile.load(\(self.catalogURI) failed (\(error)")
				if self.sqliteDBFileName == ":memory:" {
					fatalError("\(name(self)).load: failed to load in-memory catalog database")
				}
				if FileManager.default.fileExists(atPath: self.dbPath) == false {
					failed = true
					return
				}
				self.db = SQLiteQuery.dbOpen(path: self.dbPath, flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_CREATE)!
				self.state = .ready
				return
			}
			let mutex = NSLock()
			self.sourceBytes = UInt(file.size)
			if let aliasesURI = self.aliasesURI, let aliasesURL = URL(string: aliasesURI), let aliasesCSV = aliasesURL.path.split(separator: "/").last {
				let fileName = String(aliasesCSV)
				let aliasesPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName).path
				do {
					try FileManager.default.removeItem(atPath: aliasesPath)
				} catch {
					// no-op
				}
				mutex.lock()
				TextFile(fileName).fetch(aliasesURI) { (success, error) in
					if success == false {
						print("\(name(self)).load: TextFile.load(\(aliasesURI) failed (\(error)")
						failed = true
						mutex.unlock()
						return
					}
					for _line in TextFile(fileName) {
						let line = _line
							.trimmingCharacters(in: .whitespacesAndNewlines)
							.uppercased()
						if line.first == "#" {
							continue;
						}
						var splitLine = line.split(separator: ",")
						var string = ""
						if line.first != "," {
							string = String(splitLine.removeFirst())
						}
						for alias in splitLine {
							let numWords = alias.split(separator: " ").count
							if numWords > self.maxAliasWords {
								self.maxAliasWords = numWords
							}
							self.alias[String(alias)] = string
						}
					}
					mutex.unlock()
				}
			}
			if let titleHintsURI = self.titleHintsURI, let titleHintsURL = URL(string: titleHintsURI), let titleHintsCSV = titleHintsURL.path.split(separator: "/").last {
				let fileName = String(titleHintsCSV)
				let aliasesPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName).path
				do {
					try FileManager.default.removeItem(atPath: aliasesPath)
				} catch {
					// no-op
				}
				mutex.lock()
				TextFile(fileName).fetch(titleHintsURI) { (success, error) in
					if success == false {
						print("\(name(self)).load: TextFile.load(\(titleHintsURI) failed (\(error)")
						failed = true
						mutex.unlock()
						return
					}
					for _line in TextFile(fileName) {
						let line = _line
							.trimmingCharacters(in: .whitespacesAndNewlines)
							.replacingOccurrences(of: "\\", with: "")
							.uppercased()
						if line.first == "#" {
							continue;
						}
						self.titleHints.insert(line)
					}
					mutex.unlock()
				}
			}
			// fetch brand hints metadata
			if let brandHintsURI = self.brandHintsURI, let brandHintsURL = URL(string: brandHintsURI), let brandHintsCSV = brandHintsURL.path.split(separator: "/").last {
				let fileName = String(brandHintsCSV)
				let brandHintsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName).path
				do {
					try FileManager.default.removeItem(atPath: brandHintsPath)
				} catch {
					// no-op
				}
				mutex.lock()
				TextFile(fileName).fetch(brandHintsURI) { (success, error) in
					if success == false {
						print("\(name(self)).load: TextFile.load(\(brandHintsURI) failed (\(error)")
						failed = true
						self.state = .failed
						mutex.unlock()
						return
					}
					for _line in TextFile(fileName) {
						let line = _line
							.trimmingCharacters(in: .whitespacesAndNewlines)
							.replacingOccurrences(of: "\"", with: "")
							.uppercased()
						if line.first == "#" {
							continue;
						}
						var splitLine = line.split(separator: ",")
						var maybeBrand = String(splitLine[0])
						splitLine.removeFirst()
						let numWords = maybeBrand.split(separator: " ").count
						if maybeBrand.first == "!" {
							// not a brand
							maybeBrand.removeFirst()
							if numWords > self.maxBrandWords {
								self.maxBrandWords = numWords
							}
							self.notBrands.insert(maybeBrand)
							for string in splitLine {
								let alias = String(string).trimmingCharacters(in: .whitespaces)
								let numWords = alias.split(separator: " ").count
								if numWords > self.maxAliasWords {
									self.maxAliasWords = numWords
								}
								self.alias[alias] = maybeBrand
							}
						} else {
							// must be a brand
							if numWords > self.maxBrandWords {
								self.maxBrandWords = numWords
							}
							self.brandNames.insert(maybeBrand)
							for string in splitLine {
								let alias = String(string).trimmingCharacters(in: .whitespaces)
								self.brandAlias[alias] = maybeBrand
							}
						}
					}
					mutex.unlock()
				}
			}
			// fetch brand trademarks metadata
			if let brandMarksURI = self.brandMarksURI, let brandMarkURL = URL(string: brandMarksURI), let brandMarksCSV = brandMarkURL.path.split(separator: "/").last {
				let fileName = String(brandMarksCSV)
				let brandMarksPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName).path
				do {
					try FileManager.default.removeItem(atPath: brandMarksPath)
				} catch {
					// no-op
				}
				mutex.lock()
				TextFile(fileName).fetch(brandMarksURI) { (success, error) in
					if success == false {
						print("\(name(self)).load: TextFile.load(\(brandMarksURI) failed (\(error)")
						failed = true
						mutex.unlock()
						return
					}
					for _line in TextFile(fileName) {
						let line = _line
							.trimmingCharacters(in: .whitespacesAndNewlines)
							.replacingOccurrences(of: "\"", with: "")
							.uppercased()
						if line.first == "#" {
							continue;
						}
						var splitLine = line.split(separator: ",")
						let brand = String(splitLine.removeFirst())
						let numWords = brand.split(separator: " ").count
						if numWords > self.maxProductWords {
							self.maxProductWords = numWords
						}
						for word in splitLine {
							let brandMark = String(word).trimmingCharacters(in: .whitespaces)
							self.brandMark[brandMark] = brand
						}
					}
					mutex.unlock()
				}
			}
			mutex.lock()
			if failed {
				if self.isInMemoryDB {
					fatalError("\(name(self)).load: failed to load in-memory catalog database")
				}
				if self.dbPath == "" {
					self.state = .failed
				} else {
					self.db = SQLiteQuery.dbOpen(path: self.dbPath, flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX) // | SQLITE_OPEN_CREATE)!
					self.state = .ready
				}
				mutex.unlock()
				self.observer?.modelDidUpdate()
				return
			}
			// delete existing database if exists
			if self.isInMemoryDB == false, FileManager.default.fileExists(atPath: self.dbPath) {
				do {
					try FileManager.default.removeItem(at: URL(fileURLWithPath: self.dbPath))
				}
				catch {
					fatalError("\(name(self)).load: failed to delete \(self.dbPath)")
				}
			}
			let _ = Task(priority: .utility) {
				self.importSource()
			}
			mutex.unlock()
		}
	}
	
	private func importSource() {
		if sqliteDBFileName == ":memory:" {
			db = SQLiteQuery.dbOpen(path: sqliteDBFileName, flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_MEMORY | SQLITE_OPEN_URI )!
		} else {
			self.dbPath = FileManager.default
				.urls(for: .documentDirectory, in: .userDomainMask)
				.first!.appendingPathComponent(sqliteDBFileName).path
			print("dbPath=\(dbPath)")
			db = SQLiteQuery.dbOpen(path: dbPath, flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_CREATE)!
		}
		guard let db = db else {
			fatalError("\(name(self)).importSource: failed to unwrap db")
		}
		
		Item(db).createSQLiteTable()
		Brand(db).createSQLiteTable()
		Title(db).createSQLiteTable()
		Color(db).createSQLiteTable()
		Size(db).createSQLiteTable()

		let insertItem = SQLiteQuery(db, "insert into item ( serial, price, brandId, titleId, colorId, sizeId ) values ( ?, ?, ?, ?, ?, ? )")
		let insertBrand = SQLiteQuery(db, "insert into brand ( brand ) values ( ? )")
		let insertTitle = SQLiteQuery(db, "insert into title ( title ) values ( ? )")
		let insertColor = SQLiteQuery(db, "insert into color ( color, numeric ) values ( ?, ? )")
		let insertSize = SQLiteQuery(db, "insert into size ( size ) values ( ? )")
		
		catalogCSV = TextFile(catalogFileName)
		
		var itemId: Int64 = 0
		var lines = [String]()
		guard let input = catalogCSV else {
			fatalError("\(name(self)).importSource: failed to unwrap input")
		}
		for line in input {
			if loopCount == 0 || line.first == "#" {
				loopCount += 1
				continue;
			}
			loopCount += 1
			lines.append(line)
		}
		
		// import catalog into sqlite
		
		self.loopIndex = 0
		self.loopCount = lines.count
		self.state = .loading
		
		assert(SQLiteQuery.begin(db))
		
		for line in lines {
			let fields = line.uppercased().split(separator: ",")
			let serial = String(fields[0])
			let rawTitle = String(fields[1]).trimmingCharacters(in: .whitespaces).uppercased()
			let normalizedTitle = getNormalizedTitle(rawTitle)
			let aliasedTitle = getAliasedTitle(normalizedTitle)
			var title = getStrippedTitle(aliasedTitle)
			let listPrice = Float(String(fields[2]))!
			let salePrice = Float(String(fields[3]))!
			let price = String(salePrice < listPrice ? fields[2] : fields[3])
			var color = String(String(fields[4]).split(separator: " ")[0])
			color = Color.normalize(color)
			let numeric = ""
			let size = String(fields[5].replacingOccurrences(of: "\n", with: ""))
			var key = "\(title)-\(price)-\(color)-\(size)"
			if let _itemId = itemIds[key] {
				itemId = _itemId
			} else if itemKeys.contains(key) == false {
				var colorId: Int64
				if let _colorId = colorIds[color] {
					colorId = _colorId
				} else {
					insertColor.clearBindings()
					insertColor.reset()
					insertColor.bindString(1, color)
					insertColor.bindString(2, numeric)
					if insertColor.execute() {
						colorId = SQLiteQuery.lastInsertRowId(db)
						colorIds[color] = colorId
					} else {
						fatalError("\(name(self)).importSource: insertColor.execute() failed")
					}
				}
				var sizeId: Int64 = 0
				if let _sizeId = sizeIds[size] {
					sizeId = _sizeId
				} else {
					insertSize.clearBindings()
					insertSize.reset()
					insertSize.bindString(1, size)
					if insertSize.execute() {
						sizeId = SQLiteQuery.lastInsertRowId(db)
						sizeIds[size] = sizeId
					} else {
						fatalError("\(name(self)).importSource: insertSize.execute() failed")
					}
				}
				// populate itemBrands for multi-brand records
				var itemBrands = Set<String>()
				var itemBrandMarks = [String:String]()
				var index = 0
				var titleWords = title.split(separator: " ")
				while index < titleWords.count {
					var maybeBrand = ""
					for maybeBrandLen in (1...self.maxBrandWords).reversed() {
						if maybeBrandLen > titleWords.count - index {
							continue
						}
						if index + maybeBrandLen > titleWords.count {
							break
						}
						for maybeBrandWord in titleWords[index..<index+maybeBrandLen] {
							maybeBrand += (maybeBrand.count > 0 ? " " : "") + maybeBrandWord
						}
						if let alias = brandAlias[maybeBrand] {
							title = " \(title) "
								.replacingOccurrences(of: " \(maybeBrand) ", with: " \(alias) ")
								.trimmingCharacters(in: .whitespaces)
							titleWords = title.split(separator: " ")
							let numBrandWords = maybeBrand.split(separator: " ").count
							let numAliasWords = alias.split(separator: " ").count
							maybeBrand = alias
							index += numAliasWords - numBrandWords + 1
						} else if let brand = brandMark[maybeBrand] {
							// remove brandmark from title
							itemBrandMarks[brand] = maybeBrand
							title = " \(title) "
								.replacingOccurrences(of: " \(maybeBrand)", with: "")
								.trimmingCharacters(in: .whitespaces)
							titleWords = title.split(separator: " ")
							index -= maybeBrand.split(separator: " ").count
							if index < 0 {
								index = 0
							}
						}
						if brandNames.contains(maybeBrand) {
							title = " \(title) "
								.replacingOccurrences(of: " \(maybeBrand)", with: "")
								.trimmingCharacters(in: .whitespaces)
							titleWords = title.split(separator: " ")
							index -= maybeBrand.split(separator: " ").count
							if index < 0 {
								index = 0
							}
							break
						} else if notBrands.contains(maybeBrand) {
							// skip entire maybeBrand string
							index += maybeBrand.split(separator: " ").count
							maybeBrand = ""
							break
						} else {
							if maybeBrand.split(separator: " ").count == 1 {
								index += 1
							}
							maybeBrand = ""
						}
					}
					let brandWords = maybeBrand.split(separator: " ")
					if brandWords.count > 1 || maybeBrand != "" {
						itemBrands.insert(maybeBrand)
					}
				}
				for (brand, _) in itemBrandMarks {
					itemBrands.insert(brand)
				}
				if itemBrands.count == 0 {
					itemBrands.insert("?")
				}
				let sortedBrands = Array(itemBrands).sorted { $0 < $1 }
				for _brand in sortedBrands {
					let brand = _brand
					var brandId: Int64 = 0
					if let _brandId = brandIds[brand] {
						brandId = _brandId
					} else {
						insertBrand.clearBindings()
						insertBrand.reset()
						insertBrand.bindString(1, brand)
						if insertBrand.execute() {
							brandId = SQLiteQuery.lastInsertRowId(db)
							brandIds[brand] = brandId
						} else {
							fatalError("\(name(self)).importSource: insertBrand.execute() failed")
						}
					}
					if brandItems[brand] == nil {
						brandItems[brand] = Set<String>()
					}
					var brandedTitle = title
					let brandMark = itemBrandMarks[brand]
					if brandMark != nil {
						brandedTitle = "\(brandMark!) \(title)".trimmingCharacters(in: .whitespaces)
					}
					let brandedTitleParts = brandedTitle.split(separator: "/")
					if (brandedTitle != "INFINITY" && Float(brandedTitle) != nil)
						|| (brandedTitleParts.count == 2 && Float(brandedTitleParts[0]) != nil && Float(brandedTitleParts[1]) != nil)
						|| (brandedTitle == "" && brandMark == nil)
					{
						print("*** INVALID TITLE? *** \(line.replacingOccurrences(of: "\n", with: ""))")
						loopIndex += 1
						continue
					}
					if brand != "?" {
						brandedTitle = "\(brandedTitle) (\(brand))"
					}
					key = "\(brandedTitle)-\(price)-\(color)-\(size)"
					var titleId: Int64
					if let _titleId = titleIds[brandedTitle] {
						titleId = _titleId
					} else {
						insertTitle.clearBindings()
						insertTitle.reset()
						insertTitle.bindString(1, brandedTitle)
						if insertTitle.execute() {
							titleId = SQLiteQuery.lastInsertRowId(db)
							titleIds[brandedTitle] = titleId
						} else {
							fatalError("\(name(self)).importSource: insertTitle.execute() failed")
						}
					}
					if let _itemId = itemIds[key] {
						itemId = _itemId
					} else if itemKeys.contains(key) == false {
						insertItem.clearBindings()
						insertItem.reset()
						insertItem.bindString(1, serial)
						insertItem.bindString(2, price)
						insertItem.bindInt64(3, brandId)
						insertItem.bindInt64(4, titleId)
						insertItem.bindInt64(5, colorId)
						insertItem.bindInt64(6, sizeId)
						if insertItem.execute() == false {
							fatalError("\(name(self)).importSource: insertItem.execute() failed")
						}
						itemId = SQLiteQuery.lastInsertRowId(db)
						itemIds[key] = itemId
						itemKeys.insert(key)
					}
				}
				loopIndex += 1
				if self.loopIndex % modelDidUpdateInterval == 0 {
					self.observer?.modelDidUpdate()
				}
			}
		}
		insertItem.finalize()
		insertBrand.finalize()
		insertTitle.finalize()
		insertColor.finalize()
		insertSize.finalize()
		
		loopCount = brandItems.count
		loopIndex = 0
		
		assert(SQLiteQuery.commit(db))
		
		state = .indexing
		
		Item(db).createSQLiteIndexes()
		Brand(db).createSQLiteIndexes()
		Title(db).createSQLiteIndexes()
		Color(db).createSQLiteIndexes()
		Size(db).createSQLiteIndexes()
		
		state = .ready
	}
	
	private func stripDashesFromTitle(_ title: String) -> String {
		var stripped = ""
		let splitTitle = title.split(separator: " ")
		for _word in splitTitle {
			var word = _word
			while word.last == "-" {
				word.removeLast()
			}
			if word == "" {
				continue
			}
			if title.count > 0 {
				stripped += " "
			}
			stripped += word
		}
		return stripped.trimmingCharacters(in: .whitespaces)
	}
	
	private func stripSlashesFromTitle(_ title: String) -> String {
		var stripped = ""
		let splitTitle = title.split(separator: " ")
		for _word in splitTitle {
			var word = _word
			while word.last == "/" {
				word.removeLast()
			}
			if word == "" {
				continue
			}
			if title.count > 0 {
				stripped += " "
			}
			stripped += word
		}
		return stripped.trimmingCharacters(in: .whitespaces)
	}
	
	private func getAliasedTitle(_ rawTitle: String) -> String {
		let titleWords = rawTitle.split(separator: " ")
		var aliased = ""
		var i = 0
		while i < titleWords.count {
			for j in (i..<i+maxAliasWords).reversed() {
				if j >= titleWords.count {
					continue
				}
				let maybeAlias = titleWords[i...j].joined(separator: " ")
				if notBrands.contains(maybeAlias) {
					if aliased != "", maybeAlias != "" {
						aliased += " "
					}
					aliased += maybeAlias
					i += maybeAlias.split(separator: " ").count
					break
				} else if let alias = alias[maybeAlias] {
					if aliased != "", alias != "" {
						aliased += " "
					}
					aliased += alias
					i += maybeAlias.split(separator: " ").count
					break
				} else if maybeAlias.split(separator: " ").count == 1 {
					if aliased != "" {
						aliased += " "
					}
					aliased += maybeAlias
					i += 1
				}
			}
		}
		if aliased.last == "-" {
			aliased.removeLast()
		}
		return aliased
	}
	
	private func getStrippedTitle(_ string: String) -> String {
		// strips extraneous trailing text
		var title = string
		if title.hasSuffix(" 1/4") || title.hasSuffix(" 1/2") || title.hasSuffix(" 3/4") {
			title += " ZIP"
		} else if title.hasSuffix("2T") {
			title.removeLast()
			title.removeLast()
		} else if title.hasSuffix("4/7") || title.hasSuffix("46X") {
			title.removeLast()
			title.removeLast()
			title.removeLast()
		} else if title.hasSuffix("2T/4") {
			title.removeLast()
			title.removeLast()
			title.removeLast()
			title.removeLast()
		} else if title.hasSuffix("2T/4T") || title.hasSuffix("1224M") {
			title.removeLast()
			title.removeLast()
			title.removeLast()
			title.removeLast()
			title.removeLast()
		}
		return stripSlashesFromTitle(title)
	}

	private func getNormalizedTitle(_ rawTitle: String) -> String {
		let fixedRawTitle = rawTitle.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "''", with: "\"")
		var splitRawTitle = fixedRawTitle.split(separator: "-")
		if splitRawTitle.count == 1 {
			return stripDashesFromTitle(fixedRawTitle)
		}
		let numDashes = splitRawTitle.count - 1
		if numDashes == 0 {
			return stripDashesFromTitle(fixedRawTitle)
		}
		// one or more dashes if here
		let lastPart = String(splitRawTitle[numDashes])
		if let first = lastPart.first, first.isWhitespace {
			return stripDashesFromTitle(fixedRawTitle)
		}
		let firstWordOfLastPart = String(lastPart.split(separator: " ")[0])
		if titleHints.contains(firstWordOfLastPart) == false, brandAlias[firstWordOfLastPart] == nil {
			splitRawTitle.removeLast()
			return stripDashesFromTitle(splitRawTitle.joined(separator: "-").trimmingCharacters(in: .whitespaces))
		}
		return stripDashesFromTitle(splitRawTitle.joined(separator: "-").trimmingCharacters(in: .whitespaces))
	}
}
