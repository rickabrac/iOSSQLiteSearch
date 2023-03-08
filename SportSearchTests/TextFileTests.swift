//
//  TextFileTests.swift
//  SportSearchTests
//  Created by Rick Tyler
//

import XCTest
@testable import SportSearch

class TextFileTests: XCTestCase {
	
	let input = "TestTextFile.txt"
	
	override func tearDownWithError() throws {
		// delete existing input file from documents
		let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(input).path
		if FileManager.default.fileExists(atPath: path) {
			do { try FileManager.default.removeItem(at: URL(fileURLWithPath: path)) }
			catch { fatalError("testTextFile: failed to delete \(path)") }
		}
		try super.tearDownWithError()
	}

    func testTextFile() throws {
		// load file from URL and verify contents
		let stooges = ["Larry", "Moe", "Curly"]
		let testFile = TextFile(input)
		let copiedLocally = self.expectation(description: "local file instantiated")
		testFile.fetch(input) { (success, error) in
			XCTAssert(success)
			var i = 0
			DispatchQueue.main.sync {
				for line in testFile {
					switch i {
					case 0:
						XCTAssert(line == stooges[i])
					case 1:
						XCTAssert(line == stooges[i])
					case 2:
						XCTAssert(line == stooges[i])
					default:
						XCTFail()
					}
					i += 1
				}
				copiedLocally.fulfill()
			}
		}
		waitForExpectations(timeout: 5000)
		// verify previously loaded file
		var i = 0
		for line in TextFile(input) {
			switch i {
			case 0:
				XCTAssert(line == stooges[0])
			case 1:
				XCTAssert(line == stooges[1])
			case 2:
				XCTAssert(line == stooges[2])
			default:
				fatalError("TextFileTests.testTextFile: unexpected case")
			}
			i += 1
		}
    }
}
