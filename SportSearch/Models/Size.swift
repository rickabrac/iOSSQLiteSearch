//
//  Size.swift
//  SportSearch
//  Created by Rick Tyler
//

class Size: SQLiteTable {
	
	override init( _ db: OpaquePointer?) {
		super.init(db)
		self.db = db
	}
	
	override var createTableString: String {
		"""
		create table if not exists size (
			id      INTEGER NOT NULL PRIMARY KEY,
			size    STRING NOT NULL
		)
		"""
	}
	
	override var createIndexStrings: [String] {
		return [
			"create index if not exists size_id_size on size ( id, size )"
		]
	}
}
