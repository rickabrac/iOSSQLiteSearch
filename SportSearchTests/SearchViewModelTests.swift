//
//  SearchViewModelTests.swift
//  SportSearchTests
//  Created by Rick Tyler
//

import XCTest
@testable import SportSearch
import SnapshotTesting

private final class MockDispatchQueue: SynchronousDispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void) {
		work()
	}
}

class SearchViewModelTests: XCTestCase, Observer {
	var vm: SearchViewModel!
	let inputs = [
		"hockey pant",
		"polo logo",
		"polo logo /nike",
		"woven pants",
		"/",
		"#261000",
		"men’s long sleeve", "men long sleeve", "mens’ long sleeve",
		"women’s shorts", "women shorts", "womens’ shorts",
		"boy’s shorts", "boy shorts", "boys’ shorts",
		"girl’s shorts", "girl shorts", "girls’ shorts",
		"v-neck", "vneck"
	]
	let mensResult = [
		Item(serial: "", brand: "", title: "MEN'S ECLIPSE LONG SLEEVE", price: ""),
		Item(serial: "", brand: "NIKE", title: "MEN'S LOCKER LONG SLEEVE (NIKE)", price: "19.99"),
		Item(serial: "", brand: "?", title: "MEN'S LONG SLEEVE CRAVE TRG JERSEY", price: "19.99"),
		Item(serial: "", brand: "NIKE", title: "MEN'S PLAYMAKER II LONG SLEEVE (NIKE)", price: "24.99"),
		Item(serial: "", brand: "NIKE", title: "MEN'S PLAYMAKER LONG SLEEVE (NIKE)", price: "24.99"),
		Item(serial: "", brand: "NIKE", title: "MEN'S PTH11 LONG SLEEVE (NIKE)", price: "44.99"),
		Item(serial: "", brand: "NIKE", title: "MEN'S ROOKIE LONG SLEEVE (NIKE)", price: "22.99")
	]
	let womensResult = [
		Item(serial: "", brand: "XY", title: "CORE VENTED COMP SHORTS WOMEN\'S (XY)", price: "20.00"),
		Item(serial: "", brand: "NIKE", title: "WOMEN\'S COACH\'S SHORTS (NIKE)", price: "49.99"),
		Item(serial: "", brand: "AF", title: "WOMEN\'S SHOWTIME SHORTS (AF)", price: "80.00"),
		Item(serial: "", brand: "?", title: "WWP WOMEN\'S BACKPACK SHORTS", price: "29.99"),
	]
	let boysResult = [
		Item(serial: "", brand: "NIKE", title: "ACTIVE BOY\'S SHORTS (NIKE)", price: "19.99"),
		Item(serial: "", brand: "NIKE", title: "EURO BOY\'S SHORTS (NIKE)", price: "29.99")
	]
	let girlsResult = [
		Item(serial: "", brand: "?", title: "IT GIRL\'S KNIT SHORTS", price: "25.00"),
		Item(serial: "", brand: "NIKE", title: "TEAM GIRL\'S SHORTS (NIKE)", price: "")
	]
	let vneckResult = [
		Item(serial: "", brand: "NIKE", title: "CLUB SLUB V-NECK SHORT SLEEVE (NIKE)", price: ""),
		Item(serial: "", brand: "UNDER ARMOUR", title: "HEATGEAR TOUCH LONG SLEEVE V-NECK (UNDER ARMOUR)", price: "20.00"),
		Item(serial: "", brand: "NIKE", title: "LEVEL V-NECK TEE (NIKE)", price: "19.99"),
		Item(serial: "", brand: "", title: "LONG SLEEVE V-NECK TEE", price: ""),
		Item(serial: "", brand: "CC", title: "PLUNGE V-NECK TEE (CC)", price: "24.99"),
		Item(serial: "", brand: "", title: "SHORT SLEEVE V-NECK TEE", price: ""),
		Item(serial: "", brand: "CC", title: "SLUB SHORT SLEEVE V-NECK (CC)", price: ""),
		Item(serial: "", brand: "XY", title: "TACTICAL V-NECK (XY)", price: "24.99"),
		Item(serial: "", brand: "NIKE", title: "TOUCH LONG SLEEVE V-NECK (NIKE)", price: "20.00"),
		Item(serial: "", brand: "XY", title: "TOUCH SHORT SLEEVE V-NECK (XY)", price: "29.99"),
		Item(serial: "", brand: "?", title: "WOMEN'S COTTON V-NECK BLANK", price: "")
	]

    override func setUpWithError() throws {
		try super.setUpWithError()
		copyBundleFileToDocs("TestCatalog.sqlite")
		vm = SearchViewModel(sqliteDBFileName: "TestCatalog.sqlite")
		vm.dispatchQueue = MockDispatchQueue.self()
		vm.state = .ready
		vm.observer = self
    }

	func modelDidUpdate() {
		if vm.prevSearch == "" || vm.state == .searching {
			return
		}
		var item: Item
		switch vm.prevSearch {
			
		case inputs[0]:
			// "hockey pant"
			XCTAssert(vm.result.count == 3)
			item = vm.result[0]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "HOCKEY FITTED PANTS")
			XCTAssert(item.price == "34.99")
			item = vm.result[1]
			XCTAssert(item.brand == "")
			XCTAssert(item.title == "HOCKEY PANTS")
			XCTAssert(item.price == "")
			item = vm.result[2]
			XCTAssert(item.brand == "")
			XCTAssert(item.title == "HOCKEY WARM-UP PANTS")
			XCTAssert(item.price == "")
			
		case inputs[1]:
			// "polo logo"
			XCTAssert(vm.result.count == 5)
			item = vm.result[0]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "BIG LOGO POLO")
			XCTAssert(item.price == "")
			item = vm.result[1]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "BIG LOGO PRINT POLO")
			XCTAssert(item.price == "54.99")
			item = vm.result[2]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "EXPLODED LOGO LONG SLEEVE POLO")
			XCTAssert(item.price == "49.99")
			item = vm.result[3]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "EXPLODED LOGO SHORT SLEEVE POLO (NIKE)")
			XCTAssert(item.price == "")
			item = vm.result[4]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "TEMPEST LOGO PRINT POLO (NIKE)")
			XCTAssert(item.price == "44.97")
			
		case inputs[2]:
			// "polo logo /nike"
			XCTAssert(vm.result.count == 2)
			item = vm.result[0]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "EXPLODED LOGO SHORT SLEEVE POLO (NIKE)")
			XCTAssert(item.price == "")
			item = vm.result[1]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "TEMPEST LOGO PRINT POLO (NIKE)")
			XCTAssert(item.price == "44.97")
			
		case inputs[3]:
			// "woven pant"
			XCTAssert(vm.result.count == 9)
			item = vm.result[0]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "ADVANCE WOVEN PANTS (NIKE)")
			XCTAssert(item.price == "")
			item = vm.result[1]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "ATTACK WOVEN PANTS (NIKE)")
			XCTAssert(item.price == "17.50")
			item = vm.result[2]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "CRAVE WOVEN WARM-UP PANTS")
			XCTAssert(item.price == "34.99")
			item = vm.result[3]
			XCTAssert(item.brand == "WU WEAR")
			XCTAssert(item.title == "IGNITION WOVEN PANTS (WU WEAR)")
			XCTAssert(item.price == "39.99")
			item = vm.result[4]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "RUMBLE WOVEN PANTS (NIKE)")
			XCTAssert(item.price == "")
			item = vm.result[5]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "SKILL WOVEN PANTS")
			XCTAssert(item.price == "24.97")
			item = vm.result[6]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "TORQUE WOVEN PANTS")
			XCTAssert(item.price == "19.97")
			item = vm.result[7]
			XCTAssert(item.brand == "")
			XCTAssert(item.title == "TRANSIT WOVEN PANTS")
			XCTAssert(item.price == "")
			item = vm.result[8]
			XCTAssert(item.brand == "WU WEAR")
			XCTAssert(item.title == "WOVEN PANTS (WU WEAR)")
			XCTAssert(item.price == "25.00")
			
		case inputs[4]:
			// "/" (all brands)
			let expected = [
				"10K FORCE", "AF", "ALL AROUND", "ALLSEASONGEAR", "AYTON", "BASE", "BGS", "BL", "BPS", "BRAWLER", "BTS",
				"BURLEY", "CATALYST", "CC", "CGI", "COMBINE", "COMPFIT", "CRESTABLE", "CTG", "DFO", "DICK'S", "DSG",
				"ELEMENTS", "ELEVATED", "ELITE", "ESCAPE", "EU", "EVO", "FT", "GENERAL", "GK", "HOME & AWAY", "HUNDO",
				"IOF", "MFO", "MOUNTAIN", "MPZ", "NIKE", "OFC", "ON FIELD", "PIP", "PTH", "RALLY", "RECHARGE",
				"REVENANT", "SC30", "SCOUT", "SIGNATURE", "SKAGGER", "SLIPSTREAM", "SONIC", "SPILLIKINS", "STORM", "TAC",
				"TBD", "TECHNOCHIC", "TG", "TM", "TOLUCA", "UNDER ARMOUR", "VARSITY", "VELOCITY", "WEBB", "WU WEAR", "XY"
			]
			XCTAssert(vm.result.count == 65)
			var i = 0
			for item in vm.result {
				if item.brand != expected[i] {
					print("\(i) \(item.brand) != \(expected[i])")
				}
				XCTAssert(item.brand == expected[i])
				XCTAssert(item.title == "")
				XCTAssert(item.price == "")
				i += 1
			}
			
		case inputs[5]:
			// "#261000" (serial number fragment search)
			XCTAssert(vm.result.count == 7)
			item = vm.result[0]
			XCTAssert(item.brand == "NIKE")
			XCTAssert(item.title == "CLASSIC REDBUD POLO (NIKE)")
			XCTAssert(item.price == "59.99")
			item = vm.result[1]
			XCTAssert(item.brand == "XY")
			XCTAssert(item.title == "PREP SHORTS (XY)")
			XCTAssert(item.price == "24.99")
			item = vm.result[2]
			XCTAssert(item.brand == "CC")
			XCTAssert(item.title == "SLUB TEE (CC)")
			XCTAssert(item.price == "10.99")
			item = vm.result[3]
			XCTAssert(item.brand == "SKAGGER")
			XCTAssert(item.title == "VOLLEYBALL KNEE PAD (SKAGGER)")
			XCTAssert(item.price == "9.97")
			item = vm.result[4]
			XCTAssert(item.brand == "ESCAPE")
			XCTAssert(item.title == "WOVEN WIND/WATER JACKET (ESCAPE)")
			XCTAssert(item.price == "69.99")
			item = vm.result[5]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "WWP BACKPACK")
			XCTAssert(item.price == "149.99")
			item = vm.result[6]
			XCTAssert(item.brand == "?")
			XCTAssert(item.title == "WWP WOMEN'S BACKPACK TEE")
			XCTAssert(item.price == "24.99")
	
		default:
			let prefix3 = String(vm.prevSearch[..<Substring.Index(utf16Offset: 3, in:vm.prevSearch)])
			switch prefix3 {
			case "men":
				XCTAssert(vm.result.count == mensResult.count)
				var i = 0
				for item in vm.result  {
					XCTAssert(item.brand == mensResult[i].brand)
					XCTAssert(item.title == mensResult[i].title)
					XCTAssert(item.price == mensResult[i].price)
					i += 1
				}
			case "wom":
				XCTAssert(vm.result.count == womensResult.count)
				var i = 0
				for item in vm.result  {
					XCTAssert(item.brand == womensResult[i].brand)
					XCTAssert(item.title == womensResult[i].title)
					XCTAssert(item.price == womensResult[i].price)
					i += 1
				}
			case "boy":
				XCTAssert(vm.result.count == boysResult.count)
				var i = 0
				for item in vm.result  {
					XCTAssert(item.brand == boysResult[i].brand)
					XCTAssert(item.title == boysResult[i].title)
					XCTAssert(item.price == boysResult[i].price)
					i += 1
				}
			case "gir":
				XCTAssert(vm.result.count == girlsResult.count)
				var i = 0
				for item in vm.result  {
					XCTAssert(item.brand == girlsResult[i].brand)
					XCTAssert(item.title == girlsResult[i].title)
					XCTAssert(item.price == girlsResult[i].price)
					i += 1
				}
			case "vne":
				fallthrough
			case "v-n":
				XCTAssert(vm.result.count == vneckResult.count)
				var i = 0
				for item in vm.result  {
print("BRAND\(i) [\(item.brand)] [\(vneckResult[i].brand)]")
					XCTAssert(item.brand == vneckResult[i].brand)
					XCTAssert(item.title == vneckResult[i].title)
					XCTAssert(item.price == vneckResult[i].price)
					i += 1
				}
			default:
				fatalError("SearchViewModelTests.modelDidUpdate: unknown test")
			}
		}
	}
	
    func testSearchViewModel() throws {
		for input in inputs {
			vm.search(input)
		}
    }
}
