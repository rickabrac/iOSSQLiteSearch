//
//  SQLiteQuery.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation
import SQLite3

var sqliteQueries = Set<String>()

class SQLiteQuery {
	let db: OpaquePointer
	var sql: String
	var bound = false
	private var query: OpaquePointer?
	private var error: Int32 = 0

	init(_ db: OpaquePointer, _ sql: String) {
		self.db = db
		self.sql = sql.trimmingCharacters(in: .whitespacesAndNewlines)
			.replacingOccurrences(of: "\n", with: "")
			.replacingOccurrences(of: "\t", with: "")
		error = sqlite3_prepare_v2(db, sql, -1, &query, nil)
		if query == nil {
			fatalError("\(name(self)).init: sqlite3_prepare_v2() failed (\(String(cString: sqlite3_errmsg(db))))")
		}
		sqliteQueries.insert(self.sql)
	}
	
	// Executes the SQL statement. For select, caller must step throught results by calling repeatedly
	// until return value is false. After any successful call, use get...() methods to retrieve values
	// by column index.
	
	func execute() -> Bool {
		let sql = self.sql.lowercased()
		if sql.starts(with: "b") || sql.starts(with: "co") || sql.starts(with: "r") {
			// begin / commit / rollback
			error = sqlite3_step(query)
			if error == SQLITE_DONE {
				if bound == false && sqlite3_finalize(query) != SQLITE_OK {
					fatalError("\(name(self)).execute: sqlite3_finalized() failed on begin/commit/rollback (\(errorMessage)")
				}
				if bound == false {
					sqliteQueries.remove(self.sql)
				}
			}
			return error == SQLITE_DONE
		}
		if sql.starts(with: "s") { // select
			error = sqlite3_step(query)
			if error == SQLITE_DONE {
				if bound == false && sqlite3_finalize(query) != SQLITE_OK {
					fatalError("\(name(self)).execute: sqlite3_finalized() failed on select (\(errorMessage))")
				}
				if bound == false {
					sqliteQueries.remove(self.sql)
				}
				return false
			}
			return error == SQLITE_ROW
		}
		if sql.starts(with: "i") {
			// insert
			error = sqlite3_step(query)
			if bound == false && sqlite3_finalize(query) != SQLITE_OK {
				fatalError("\(name(self)).execute: sqlite3_finalized() failed on insert/create (\(errorMessage))")
			}
			if bound == false {
				sqliteQueries.remove(self.sql)
			}
			return error == SQLITE_DONE
		}
		if sql.starts(with: "cr") {
			// create
			error = sqlite3_step(query)
			if bound == false && error != SQLITE_CONSTRAINT && sqlite3_finalize(query) != SQLITE_OK {
				fatalError("\(name(self)).execute: sqlite3_finalized() failed on insert/create (\(errorMessage))")
			}
			if bound == false && error != SQLITE_CONSTRAINT {
				sqliteQueries.remove(self.sql)
			}
			return error == SQLITE_DONE || error == SQLITE_CONSTRAINT
		}
		if sql.starts(with: "u") { // update
			error = sqlite3_step(query)
			if bound == false && sqlite3_finalize(query) != SQLITE_OK {
				fatalError("\(name(self)).execute: sqlite3_finalized() failed on update (\(errorMessage))")
			}
			if bound == false {
				sqliteQueries.remove(self.sql)
			}
			return error == SQLITE_DONE && sqlite3_changes(db) > 0
		}
		if sql.starts(with: "d") { // delete
			error = sqlite3_step(query)
			if bound == false && sqlite3_finalize(query) != SQLITE_OK {
				fatalError("\(name(self)).execute: sqlite3_finalized() failed on delete (\(errorMessage))")
			}
			if bound == false {
				sqliteQueries.remove(sql)
			}
			return error == SQLITE_DONE && sqlite3_changes(db) > 0
		}
		fatalError("\(name(self)).execute: unsupported statement (\(self.sql))")
	}
	
	func bindString(_ colIdx: Int32, _ value: String) {
		if colIdx < 1 {
			fatalError("\(name(self)).execute: index must be > 0")
		}
		let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
		error = sqlite3_bind_text(query, colIdx, value, -1, SQLITE_TRANSIENT)
		if error != SQLITE_OK {
			fatalError("\(name(self)).execute: sqlite3_bind_text() failed (\(errorMessage)")
		}
		bound = true
	}
	
	func bindInt64(_ colIdx: Int32, _ value: Int64) {
		if colIdx < 1 {
			fatalError("\(name(self)).bindInt32: index must be > 0")
		}
		error = sqlite3_bind_int64(query, colIdx, value)
		if error != SQLITE_OK {
			fatalError("\(name(self)).bindInt32: sqlite3_bind_int() failed (\(errorMessage))")
		}
		bound = true
	}
	
	func getString(colIdx: Int32) -> String {
		guard let cString = sqlite3_column_text(query, colIdx) else { return "" }
		return String(cString: cString)
	}
	
	func getCurrency(colIdx: Int32) -> String {
		guard let cString = sqlite3_column_text(query, colIdx) else { return "0.00" }
		let string = String(cString: cString)
		let split = string.split(separator: ".")
		if split.count == 1 {
			return string + ".00"
		} else if String(split[split.count - 1]).count == 1 {
			return string + "0"
		}
		return string
	}
	
	func getInt64(colIdx: Int32) -> Int64 {
		return sqlite3_column_int64(query, colIdx)
	}
	
	var errorMessage: String {
		return String(cString: sqlite3_errmsg(query))
	}
	
	func clearBindings() {
		if bound {
			let _ = sqlite3_clear_bindings(query)
		}
	}
	
	func reset() {
		let _ = sqlite3_reset(query)
	}

	func finalize() {
		let error = sqlite3_finalize(query)
		if error != SQLITE_OK {
			fatalError("\(name(self)).finalize: sqlite3_finalized() failed (\(errorMessage)")
		}
		sqliteQueries.remove(sql)
	}
	
	static func dbOpen(path: String, flags: Int32 = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX) -> OpaquePointer? {
		var db: OpaquePointer?
		if sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK {
			return db
		}
		return nil
	}
	
	static func dbClose(_ db: OpaquePointer) {
		let	error = sqlite3_close(db)
		if error != SQLITE_OK {
			fatalError("\(name(self)).dbClose: failed (\(String(cString: sqlite3_errmsg(db)))))")
		}
	}
	
	static func begin(_ db: OpaquePointer) -> Bool {
		return SQLiteQuery(db, "begin immediate").execute()
	}
	
	static func commit(_ db: OpaquePointer) -> Bool {
		return SQLiteQuery(db, "commit").execute()
	}
	
	static func rollback(_ db: OpaquePointer) -> Bool {
		return SQLiteQuery(db, "rollback").execute()
	}
	
	static func lastInsertRowId(_ db: OpaquePointer) -> Int64 {
		return sqlite3_last_insert_rowid(db)
	}
}
