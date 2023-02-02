//
//  DetailViewTests.swift
//  SportSearchTests
//  Created by Rick Tyler
//

import XCTest
import SnapshotTesting
@testable import SportSearch

class DetailViewTests: XCTestCase {
	let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailView") as! DetailView
	var vm: DetailViewModel!
	let light = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.light)
	let dark = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.dark)
	
	override func setUpWithError() throws {
		if UIScreen.main.bounds != CGRect(x: 0.0, y: 0.0, width: 390.0, height: 844.0) {
			fatalError("Please use the iPhone 13 simulator in portrait mode for snapshot tests")
		}
		copyBundleFileToDocs("TestCatalog.sqlite")
		vm = DetailViewModel(db: SQLiteQuery.dbOpen(path:
			FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("TestCatalog.sqlite").path)!
		)
		vc.viewModel = vm
		vm.observer = vc
		vc.loadViewIfNeeded()
		try super.setUpWithError()
	}
	
	func testDetailViewBrandSelectionLight() {
		vm.loadDetails(Item(serial: "", brand: "", title: "TRANSIT WOVEN PANTS", price: ""))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testDetailViewBrandSelectionDark() {
		vm.loadDetails(Item(serial: "", brand: "", title: "TRANSIT WOVEN PANTS", price: ""))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
	
	func testDetailViewColorSelectionLight() {
		vm.loadDetails(Item(serial: "", brand: "NIKE", title: "ATTACK WOVEN PANTS (NIKE)", price: "17.50"))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testDetailViewColorSelectionDark() {
		vm.loadDetails(Item(serial: "", brand: "NIKE", title: "ATTACK WOVEN PANTS (NIKE)", price: "17.50"))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
	
	func testDetailViewPriceSelectionLight() {
		vm.loadDetails(Item(serial: "", brand: "NIKE", title: "RUMBLE WOVEN PANTS (NIKE)", price: ""))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testDetailViewPriceSelectionDark() {
		vm.loadDetails(Item(serial: "", brand: "NIKE", title: "RUMBLE WOVEN PANTS (NIKE)", price: ""))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}

	func testDetailViewItemListLight() {
		vm.loadDetails(Item(serial: "", brand: "NIKE", title: "ADVANCE WOVEN PANTS (NIKE)", price: "24.97"))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testDetailViewItemListDark() {
		vm.loadDetails(Item(serial: "", brand: "NIKE", title: "ADVANCE WOVEN PANTS (NIKE)", price: "24.97"))
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
}
