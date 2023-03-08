//
//  Brand.swift
//  SportSearch
//  Created by Rick Tyler
//

class Brand: SQLiteTable {
	
	override init( _ db: OpaquePointer?){
		super.init(db)
		self.db = db
	}
	
	override var createTableString: String {
		"""
		create table if not exists brand (
			id        INTEGER NOT NULL PRIMARY KEY,
			brand     VARCHAR(255) NOT NULL
		)
		"""
	}
	
	override var createIndexStrings: [String] {
		return [
			"create index if not exists brand_id_brand on brand ( id, brand )"
		]
	}
}
