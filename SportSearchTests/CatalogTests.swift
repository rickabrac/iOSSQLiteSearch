//
//  CatalogTests.swift
//  SportSearchTests
//  Created by Rick Tyler
//

import XCTest
@testable import SportSearch

class CatalogTests: XCTestCase {
	
	var catalog: Catalog? = nil

    override func setUpWithError() throws {
		try super.setUpWithError()
		self.catalog = Catalog("TestCatalog.csv",
			aliasesURI: "TestAliases.csv",
			titleHintsURI: "TestTitleHints.csv",
			brandHintsURI: "TestBrandHints.csv",
			brandMarksURI: "TestBrandMarks.csv"
		)
    }

	func testCatalog() throws {
		guard let catalog = catalog else {
			XCTFail()
			return
		}
		XCTAssert(catalog.state == .empty)
		catalog.load(into: ":memory:")
		while catalog.state != .ready {
			let state = catalog.state
			XCTAssert(state == .empty || state == .fetching || state == .loading || state == .indexing)
			print(catalog.state)
			sleep(1)
		}
		print("testing")
		copyBundleFileToDocs("TestCatalog.sqlite")
		let dbURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
			.first!.appendingPathComponent("TestCatalog").appendingPathExtension("sqlite")
		guard let testDatabase = SQLiteQuery.dbOpen(path: dbURL.path) else {
			XCTFail()
			return
		}
		guard let db = catalog.db else {
			fatalError("testCatalog: failed to unwrap catalog.db")
		}
		var items = [[String]]()
		let selectItems = SQLiteQuery(db,
			"select serial, price, brand, title, color, size from item" +
			" join title on titleId = title.id" +
			" join color on colorId = color.id" +
			" join size on sizeId = size.id" +
			" join brand on brandId = brand.id" +
			" order by serial, brand, title, color, size"
		)
		while selectItems.execute() {
			let serial = selectItems.getString(colIdx: 0)
			let price = selectItems.getCurrency(colIdx: 1)
			let brand = selectItems.getString(colIdx: 2)
			let title = selectItems.getString(colIdx: 3)
			let color = selectItems.getString(colIdx: 4)
			let size = selectItems.getString(colIdx: 5)
			let item: [String] = [serial, price, brand, title, color, size]
			items.append(item)
		}
		var expected = [[String]]()
		let selectTestItems = SQLiteQuery(testDatabase,
			"select serial, price, brand, title, color, size from item" +
			" join title on titleId = title.id" +
			" join color on colorId = color.id" +
			" join size on sizeId = size.id" +
			" join brand on brandId = brand.id" +
			" order by serial, brand, title, color, size"
		)
		while selectTestItems.execute() {
			let serial = selectTestItems.getString(colIdx: 0)
			let price = selectTestItems.getCurrency(colIdx: 1)
			let brand = selectTestItems.getString(colIdx: 2)
			let title = selectTestItems.getString(colIdx: 3)
			let color = selectTestItems.getString(colIdx: 4)
			let size = selectTestItems.getString(colIdx: 5)
			let testItem: [String] = [serial, price, brand, title, color, size]
			expected.append(testItem)
		}
		XCTAssert(items.count == expected.count)
		for i in 0..<items.count {
			XCTAssert(items[i] == expected[i])
		}
	}
}
