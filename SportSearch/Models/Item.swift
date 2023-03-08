//
//  Item.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation

class Item: SQLiteTable, Equatable {
	
	var serial: String = ""
	var price: String = ""
	var brand: String = ""
	var title: String = ""
	var color: String = ""
	var size: String = ""
	
	init(
		serial: String,
		brand: String,
		title: String,
		price: String,
		color: String = "",
		size: String = "",
		_ db: OpaquePointer? = nil
	){
		self.serial = serial
		self.brand = brand
		self.title = title
		self.price = price
		self.color = color
		self.size = size
		guard let db = db else {
			super.init()
			return
		}
		super.init(db)
		self.db = db
	}
	
	override init( _ db: OpaquePointer?){
		super.init(db)
		self.db = db
	}
	
	func strippedTitle() -> String {
		if title.last == ")" {
			var stripped = title
			var split = stripped.split(separator: "(")
			if split.count > 0 {
				split.removeLast()
				stripped = split.joined(separator: "(").trimmingCharacters(in: .whitespaces)
			}
			if stripped.last == ")" {
				stripped.removeLast()
			}
			return stripped
		}
		return title
	}
	
	override var createTableString: String {
		"""
		create table if not exists item (
			id           INTEGER NOT NULL PRIMARY KEY,
			serial       STRING NOT NULL,
			price        DECIMAL(4, 2) NOT NULL,
			brandId      INTEGER NOT NULL,
			titleId      INTEGER NOT NULL,
			colorId      INTEGER NOT NULL,
			sizeId       INTEGER NOT NULL
		)
		"""
	}
	
	override var createIndexStrings: [String] {
		[
		"create index if not exists item_brand_serial on item ( brandId, serial )",
		"create index if not exists item_title_id on item ( titleId )",
		"create index if not exists item_price on item ( price )",
		"create index if not exists item_color_id on item ( colorId )",
		"create index if not exists item_size_id on item ( sizeId )",
		"create index if not exists item_brand_title_price_color_size_serial on item ( titleId, brandId, price, colorId, sizeId, serial )",
		"create index if not exists item_brand_color_size_serial on item ( brandId, colorId, sizeId, serial )"
		]
	}
	
	// MARK: Equatable conformance
	
	static func == (lhs: Item, rhs: Item) -> Bool {
		return lhs.serial == rhs.serial
			&& lhs.brand == rhs.brand
			&& lhs.title == rhs.title
			&& lhs.price == rhs.price
			&& lhs.color == rhs.color
			&& lhs.size == rhs.size
	}
}
