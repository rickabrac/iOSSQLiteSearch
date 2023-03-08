//
//  Title.swift
//  SportSearch
//  Created by Rick Tyler
//

class Title: SQLiteTable {
	
	override init( _ db: OpaquePointer?){
		super.init(db)
		self.db = db
	}
	
	override var createTableString: String {
		"""
		create table if not exists title (
			id       INTEGER NOT NULL PRIMARY KEY,
			title    STRING NOT NULL
		)
		"""
	}
	
	override var createIndexStrings: [String] {
		[
		"""
		create index if not exists title_id_title on title ( id, title )
		"""
		]
	}
}
