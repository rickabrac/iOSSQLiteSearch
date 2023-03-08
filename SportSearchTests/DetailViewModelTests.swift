//
//  DetailViewModelTests.swift
//  SportSearchTests
//  Created by Rick Tyler
//

import XCTest
@testable import SportSearch
import SnapshotTesting

class DetailViewModelTests: XCTestCase, Observer {
	
	var vm: DetailViewModel!
	let inputs: [Item] = [
		Item(serial: "", brand: "", title: "TRANSIT WOVEN PANTS", price: "", color: ""),                        // brand selection
		Item(serial: "", brand: "NIKE", title: "ATTACK WOVEN PANTS (NIKE)", price: "17.50", color: ""),         // color selection
		Item(serial: "", brand: "NIKE", title: "RUMBLE WOVEN PANTS (NIKE)", price: "", color: ""),              // price selection
		Item(serial: "", brand: "", title: "TORQUE WOVEN PANTS", price: "19.97", color: ""),        // item/size list
		Item(serial: "%261000%", brand: "ESCAPE", title: "WOVEN WIND/WATER JACKET (ESCAPE)", price: "69.99")    // serial string filtering
	]
	let mutex = NSLock()

	override func setUpWithError() throws {
		try super.setUpWithError()
		copyBundleFileToDocs("TestCatalog.sqlite")
		let dbPath = FileManager.default
			.urls(for: .documentDirectory, in: .userDomainMask)
			.first!.appendingPathComponent("TestCatalog.sqlite").path
		guard let db = SQLiteQuery.dbOpen(path: dbPath) else {
			fatalError("DetailViewModelTests.setUpWithError: failed to unwrap db")
		}
		vm = DetailViewModel(db: db)
		vm.observer = self
	}

	func modelDidUpdate() {
		var item: Item
		switch vm.search {
			
		case inputs[0]:
			// brand selection
			let title = "TRANSIT WOVEN PANTS"
			XCTAssert(vm.result.count == 2)
			XCTAssert(vm.titleText == title)
			item = vm.result[0]
			XCTAssert(item.serial == "")
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == title)
			XCTAssert(item.price == "")
			XCTAssert(item.color == "")
			XCTAssert(item.size == "")
			item = vm.result[1]
			XCTAssert(item.serial == "")
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == title)
			XCTAssert(item.price == "")
			XCTAssert(item.color == "")
			XCTAssert(item.size == "")
			
		case inputs[1]:
			// color selection
			let brand = "NIKE"
			let title = "ATTACK WOVEN PANTS (NIKE)"
			let price = "17.50"
			XCTAssert(vm.titleText == "\(title) \(price)")
			XCTAssert(vm.result.count == 2)
			item = vm.result[0]
			XCTAssert(item.serial == "")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == "\(price)")
			XCTAssert(item.color == "BLACK.002")
			XCTAssert(item.size == "LG")
			item = vm.result[1]
			XCTAssert(item.serial == "")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == "\(price)")
			XCTAssert(item.color == "BLACK.041")
			XCTAssert(item.size == "LG")
			
		case inputs[2]:
			// price selection
			let brand = "NIKE"
			let title = "RUMBLE WOVEN PANTS (NIKE)"
			XCTAssert(vm.titleText == title)
			XCTAssert(vm.result.count == 2)
			item = vm.result[0]
			XCTAssert(item.serial == "")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == "24.99")
			XCTAssert(item.color == "")
			XCTAssert(item.size == "")
			item = vm.result[1]
			XCTAssert(item.serial == "")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == "34.99")
			XCTAssert(item.color == "")
			XCTAssert(item.size == "")
			
		case inputs[3]:
			// item/size list
			let brand = "?"
			let title = "TORQUE WOVEN PANTS"
			let price = "19.97"
			let color = "GREY"
			XCTAssert(vm.result.count == 6)
			item = vm.result[0]
			XCTAssert(item.serial == "2-99204184040007")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "LG")
			item = vm.result[1]
			XCTAssert(item.serial == "2-99204184040003")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "MD")
			item = vm.result[2]
			XCTAssert(item.serial == "2-99204184040009")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "SM")
			item = vm.result[3]
			XCTAssert(item.serial == "2-99204184040010")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "XL")
			item = vm.result[4]
			XCTAssert(item.serial == "2-99204184040008")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "3XL")
			item = vm.result[5]
			XCTAssert(item.serial == "2-99204184040006")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "XXL")
			
		case inputs[4]:
			// serial number search
			let brand = "ESCAPE"
			let title = "WOVEN WIND/WATER JACKET (ESCAPE)"
			let price = "69.99"
			let color = "WHITE"
			XCTAssert(vm.result.count == 5)
			XCTAssert(vm.titleText == "#261000 \(title) WHITE 69.99")
			item = vm.result[0]
			XCTAssert(item.serial == "8-99212226100006")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "LG")
			item = vm.result[1]
			XCTAssert(item.serial == "8-99212226100007")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "MD")
			item = vm.result[2]
			XCTAssert(item.serial == "8-99212226100008")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "SM")
			item = vm.result[3]
			XCTAssert(item.serial == "8-99212226100009")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "XL")
			item = vm.result[4]
			XCTAssert(item.serial == "8-99212226100005")
			XCTAssert(item.brand == brand)
			XCTAssert(item.title == title)
			XCTAssert(item.price == price)
			XCTAssert(item.color == color)
			XCTAssert(item.size == "XS")
			
		default:
			guard let search = vm.search else {
				fatalError("DetailViewModelTests.modelDidUpdate: failed to unwrap search")
			}
			print("\(search.serial) [\(search.brand)] \(search.title) color=\(search.color) price=\(search.price)")
			XCTFail()
			mutex.unlock()
			return
		}
		mutex.unlock()
	}

	func testDetailViewModel() throws {
		for item in inputs {
			mutex.lock()
			vm.loadDetails(item)
		}
	}
}
