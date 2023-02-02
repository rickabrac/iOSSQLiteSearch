//
//  SQLiteQueryTests.swift
//  SportSearchTests
//  Created by Rick Tyler
//

import XCTest
@testable import SportSearch
import SQLite3

class SQLiteQueryTests: XCTestCase {
	var db: OpaquePointer? = nil
	
    override func setUpWithError() throws {
		try super.setUpWithError()
		db = SQLiteQuery.dbOpen(path: ":memory:", flags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_MEMORY )!
		Table(db).createSQLiteTable()
    }

    func testSQLiteQuery() throws {
		guard let db = db else {
			XCTFail()
			return
		}
		let numRows = 10000
		
		// insert test
		for i in 1...numRows {
			let text = "text\(i)"
			let currency = "\(i).99"
			let insertRow = SQLiteQuery(db, "insert into test ( text, currency ) values ( '\(text)', \(currency) )")
			XCTAssert(insertRow.execute())
		}
		let selectRow = SQLiteQuery(db, "select id, text, currency from test order by id")
		var rowId: Int64 = 0
		while(selectRow.execute()) {
			rowId += 1
			XCTAssert(selectRow.getInt64(colIdx: 0) == rowId)
			XCTAssert(selectRow.getString(colIdx: 1) == "text\(rowId)")
			XCTAssert(selectRow.getCurrency(colIdx: 2) == "\(rowId).99")
		}
		XCTAssert(rowId == numRows)
		
		// update test
		for i in 1...numRows {
			let text = "\(i)text"
			let currency = "\(i).00"
			let updateRow = SQLiteQuery(db, "update test set text = '\(text)', currency = \(currency) where id = \(i)")
			XCTAssert(updateRow.execute())
		}
		rowId = 0
		let selectUpdatedRow = SQLiteQuery(db, "select id, text, currency from test order by id")
		while(selectUpdatedRow.execute()) {
			rowId += 1
			XCTAssert(selectUpdatedRow.getInt64(colIdx: 0) == rowId)
			XCTAssert(selectUpdatedRow.getString(colIdx: 1) == "\(rowId)text")
			XCTAssert(selectUpdatedRow.getCurrency(colIdx: 2) == "\(rowId).00")
		}
		
		// delete test
		for i in 1...numRows {
			let deleteRow = SQLiteQuery(db, "delete from test where id = \(i)")
			XCTAssert(deleteRow.execute())
			let countRows = SQLiteQuery(db, "select count(*) from test")
			XCTAssert(countRows.execute())
			XCTAssert(countRows.getInt64(colIdx: 0) == numRows - i)
		}
		
		// transaction test
		assert(SQLiteQuery.begin(db))
		// confirm db is empty
		let countRows = SQLiteQuery(db, "select count(*) from test")
		XCTAssert(countRows.execute())
		XCTAssert(countRows.getInt64(colIdx: 0) == 0)
		// insert one row
		let insertRow = SQLiteQuery(db, "insert into test ( text, currency ) values ( '?', '0.00' )")
		if insertRow.execute() == false {
			XCTFail()
		}
		// confirm row inserted
		countRows.reset()
		XCTAssert(countRows.execute())
		XCTAssert(countRows.getInt64(colIdx: 0) == 1)
		// perform rollback
		assert(SQLiteQuery.rollback(db))
		// confirm insertion rolled back
		countRows.reset()
		XCTAssert(countRows.execute())
		XCTAssert(countRows.getInt64(colIdx: 0) == 0)
    }
}

private class Table: SQLiteTable {
	override init( _ db: OpaquePointer?){
		super.init(db)
		self.db = db
	}
	
	override var createTableString: String {
		"""
		create table test (
			id          INTEGER NOT NULL PRIMARY KEY,
			text        STRING NOT NULL,
			currency    DECIMAL(4, 2) NOT NULL
		)
		"""
	}
	
	override var createIndexStrings: [String] { [] }
}
