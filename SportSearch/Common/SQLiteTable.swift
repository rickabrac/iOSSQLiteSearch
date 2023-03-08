//
//  SQLiteTable.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation

class SQLiteTable {
	
	var db: OpaquePointer?
	
	init(_ db: OpaquePointer? = nil) {
		self.db = db
	}
	
	func createSQLiteTable() {
		let createSizeTable = SQLiteQuery(self.db!, createTableString)
		if !createSizeTable.execute() {
			fatalError("\(name(self)).createSQLiteTable: createItemTable failed \(createSizeTable.errorMessage)")
		}
	}
	
	func createSQLiteIndexes() {
		for createItemIndexString in createIndexStrings {
			let createItemIndex = SQLiteQuery(self.db!, createItemIndexString)
			if !createItemIndex.execute() {
				fatalError("\(name(self)).createSQLiteIndexes: createItemIndex failed \(createItemIndex.errorMessage)")
			}
		}
	}
	
	func createSQLiteIndex(index: Int) {
		let createItemIndex = SQLiteQuery(self.db!, createIndexStrings[index])
		if !createItemIndex.execute() {
			fatalError("\(name(self)).createSQLiteIndex: createItemIndex failed \(createIndexStrings[index])")
		}
	}
	
	var createTableString: String {
		fatalError("\(name(self)): createTableString() unimplemented by subclass")
	}
	
	var createIndexStrings: [String] {
		fatalError("\(name(self)): createIndexStrings() unimplemented by subclass")
	}
}
