//
//  Color.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation

class Color: SQLiteTable {
	override init( _ db: OpaquePointer?){
		super.init(db)
		self.db = db
	}
	
	static func normalize(_ color: String) -> String {
		let digit = Array(color)[0]
		if digit.isNumber, let index = Int(String(digit)) {
			let names = ["BLACK", "WHITE", "BROWN", "GREEN", "BLUE", "PURPLE", "RED", "YELLOW", "ORANGE", "PINK", "NAVY"]
			return names[index] + ".\(color)"
		}
		return "\(color)"
	}
	
	override var createTableString: String {
		"""
		create table if not exists color (
			id         INTEGER NOT NULL PRIMARY KEY,
			color      STRING NOT NULL,
			numeric    STRING NOT NULL
		)
		"""
	}
	
	override var createIndexStrings: [String] {
		[
		"create index if not exists color_id_color on color ( id, color )"
		]
	}
}
