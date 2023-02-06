//
//  SearchViewTests.swift
//  SportSearchTests
//  Created by Rick Tyler
//

import XCTest
import SnapshotTesting
@testable import SportSearch

private final class TestDispatchQueue: SynchronousDispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void) {
		work()
	}
}

class SearchViewTests: XCTestCase {
	let vc = SearchView(dispatchQueue: TestDispatchQueue.self())
	var vm: SearchViewModel!
	let light = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.light)
	let dark = UITraitCollection(userInterfaceStyle: UIUserInterfaceStyle.dark)
	
    override func setUpWithError() throws {
		if UIScreen.main.bounds != CGRect(x: 0.0, y: 0.0, width: 390.0, height: 844.0) {
			fatalError("Please use the iPhone 13 simulator in portrait mode for snapshot tests")
		}
		copyBundleFileToDocs("TestCatalog.sqlite")
		vm = SearchViewModel(sqliteDBFileName: "TestCatalog.sqlite")
		vc.viewModel = vm
		vc.loadViewIfNeeded()
		vm.dispatchQueue = TestDispatchQueue.self()
		vm.observer = vc
		vm.progress = 0.5
		try super.setUpWithError()
    }
	
	func testSearchViewFetchingLight() {
		vm.state = .fetching
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testSearchViewFetchingDark() {
		vm.state = .fetching
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
	
	func testSearchViewLoadingLight() {
		vm.state = .loading
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testSearchViewLoadingDark() {
		vm.state = .loading
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}

	func testSearchViewIndexingLight() {
		vm.state = .indexing
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testSearchViewIndexingDark() {
		vm.state = .indexing
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
	
	func testSearchViewReadyLight() {
		vm.state = .ready
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testSearchViewReadyDark() {
		vm.state = .ready
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
	
	func testSearchViewResultsLight() {
		vm.state = .ready
		vm.search("logo tee")
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testSearchViewResultsDark() {
		vm.state = .ready
		vm.search("logo tee")
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}

	func testSearchViewBrandsLight() {
		vm.state = .ready
		vm.search("/")
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}

	func testSearchViewBrandsDark() {
		vm.state = .ready
		vm.search("/")
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
	
	func testSearchViewBrandSelectionLight() {
		vm.state = .ready
		vm.isSearchFieldHidden = true
		vm.search("/under")
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: light))
	}
	
	func testSearchViewBrandSelectionDark() {
		vm.state = .ready
		vm.isSearchFieldHidden = true
		vm.search("/under")
		assertSnapshot(matching: vc, as: .image(on: .iPhone13, traits: dark))
	}
}
