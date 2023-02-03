//
//  DetailViewModel.swift
//	SportSearch
//  Created by Rick Tyler
//

import Foundation
import SQLite3

class DetailViewModel: Model {
	var db: OpaquePointer
	var observer: Observer?
	private var serial = ""
	private var title = ""
	private var price = ""
	private var brand = ""
	private var color = ""
	private var brands = [String]()
	private var prices = [String]()
	private var colors = [String]()
	private var searching = false
	var result = [Item]()
	var search: Item? = nil
	 
	init(db: OpaquePointer) {
		self.db = db
	}
	
	var isSearching: Bool {
		return searching
	}
	
	func loadDetails(_ search: Item) {
		self.searching = true
		self.search = search
		self.serial = search.serial
		self.brand = search.brand.replacingOccurrences(of: "'", with: "''")
		self.title = search.title
		self.price = search.price
		self.color = search.color
		brands = []
		prices = []
		colors = []
		result = []
		let start = currentTimeMillis()
		var selectItemDetail: SQLiteQuery
		if price == "" {
			var condition = " title like '\(title.replacingOccurrences(of: "'", with: "''"))%'"
			if brand != "" {
				condition = " brand = '\(brand)' and \(condition)"
			}
			if serial != "" {
				condition += " and serial like '\(serial)'"
			}
			selectItemDetail = SQLiteQuery(db,
				"select brand, title, serial, price, color, size, brandId from item" +
				" join brand on brandId = brand.id" +
				" join title on titleId = title.id" +
				" join color on colorId = color.id" +
				" join size on sizeId = size.id" +
				" where \(condition)" +
				" order by brand, title, price, color, sizeId, serial"
			)
		} else {
			var condition = ""
			if brand != "" {
				condition = "brand = '\(brand)'"
			}
			if color != "" {
				if condition != "" {
					condition += " and "
				}
				condition += "color = '\(color)'"
			}
			if serial != "" {
				if condition != "" {
					condition += " and "
				}
				condition += "serial like '\(serial)'"
			}
			if condition != "" {
				condition += " and"
			}
			selectItemDetail = SQLiteQuery(db,
				"select brand, title, serial, price, color, size, brand.id from item" +
				" join brand on brandId = brand.id" +
				" join title on titleId = title.id" +
				" join color on colorId = color.id" +
				" join size on sizeId = size.id" +
				" where \(condition) title = '\(title.replacingOccurrences(of: "'", with: "''"))' and price = '\(price)'" +
				" order by brand, colorId, sizeId, serial"
			)
		}
		var prevBrand: String? = ""
		var prevPrice = ""
		var prevColor = ""
		var color: String = ""
		while selectItemDetail.execute() {
			let brand = selectItemDetail.getString(colIdx: 0)
			let title = selectItemDetail.getString(colIdx: 1)
			let serial = selectItemDetail.getString(colIdx: 2)
			let price = selectItemDetail.getCurrency(colIdx: 3)
			color = selectItemDetail.getString(colIdx: 4)
			let size = selectItemDetail.getString(colIdx: 5)
			let brandId = selectItemDetail.getInt64(colIdx: 6)
			let brandedSerial = "\(brandId)-\(serial)"
			let item = Item(serial: "\(brandedSerial)", brand: brand, title: title, price: price, color: color, size: size)
			result.append(item)
			if brands.count == 0 || brand != prevBrand {
				brands.append(brand)
			}
			prevBrand = brand
			if prices.count == 0 || price != prevPrice {
				prices.append(price)
			}
			prevPrice = price
			if colors.count == 0 || color != prevColor {
				colors.append(color)
			}
			prevColor = color
		}
		let tempResult = result
		result = []
		prevBrand = nil
		prevPrice = ""
		prevColor = ""
		for i in 0..<tempResult.count {
			let item = tempResult[i]
			if brands.count > 1 {
				item.title = item.strippedTitle()
				item.price = ""
				item.color = ""
				item.size = ""
				if prevBrand == nil || item.brand != prevBrand {
					item.serial = serial != "" ? serial : ""
					result.append(item)
				}
			} else if prices.count > 1 {
				item.color = ""
				item.size = ""
				if item.price != prevPrice {
					item.serial = serial != "" ? serial : ""
					result.append(item)
				}
			} else if colors.count > 1 {
				if item.color == self.color {
					item.serial = serial != "" ? serial : ""
					result.append(item)
				}
				else if self.color == "", item.color != prevColor {
					item.serial = serial != "" ? serial : ""
					result.append(item)
				}
			} else {
				self.color = item.color
				result.append(item)
			}
			prevBrand = item.brand
			prevPrice = item.price
			prevColor = item.color
		}
		print("\(currentTimeMillis() - start) ms")
		observer?.modelDidUpdate()
		searching = false
	}
	
	var titleText: String {
		var text = ""
		if serial != "" {
			text += "#\(String(serial.split(separator: "%")[0])) "
		}
		text += "\(title)"
		if color != "" {
			text += " \(color)"
		}
		if prices.count == 1, price != "" {
			text += " \(price)"
		}
		return text
	}
	
	var numberOfRows: Int {
		return brands.count > 1 ? brands.count : result.count
	}
	
	func getItem(forRowAt indexPath: IndexPath) -> Item {
		return result[indexPath.row]
	}
	
	func shouldSelect(rowAt indexPath: IndexPath) -> Bool {
		// true if selecting row will generate more results
		if brands.count < 2, prices.count < 2, colors.count < 2 {
			return false
		}
		if self.color != "" {
			return false
		}
		return true
	}
	
	func getLeftText(forRowAt indexPath: IndexPath) -> String {
		let item = result[indexPath.row]
		if brands.count < 2, prices.count < 2, colors.count < 2 {
			return item.serial
		}
		if self.color != "" {
			return item.serial
		}
		if brands.count > 1 || prices.count > 1 || colors.count > 1 {
			return ""
		}
		return item.serial
	}
	
	func getCenterText(forRowAt indexPath: IndexPath) -> String {
		if brands.count == 1, prices.count == 1, colors.count == 1 {
			return ""
		}
		if self.color != "" {
			return ""
		}
		let item = result[indexPath.row]
		if brands.count > 1 {
			return item.brand
		}
		if prices.count > 1 {
			if item.price.split(separator: ".").count == 1 {
				item.price += ".00"
			}
			return item.price
		}
		return item.color
	}
	
	func getRightText(forRowAt indexPath: IndexPath) -> String {
		let item = result[indexPath.row]
		if brands.count < 2, prices.count < 2, colors.count < 2 {
			return item.size
		}
		if self.color != "" {
			return item.size
		}
		return ""
	}
}
