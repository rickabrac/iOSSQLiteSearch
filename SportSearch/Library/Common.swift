//
//  Shared.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation

enum CatalogState {
	case empty        // initialized
	case failed       // download failed w/out cached db
	case fetching     // fetching catalog and metadata
	case loading      // loading into SQLite db
	case indexing     // indexing database
	case ready        // ready to search
	case searching    // searching
}

func name(_ obj: AnyObject) -> String {
	return String(NSStringFromClass(type(of: obj)).split(separator: ".")[1])
}

func unitTestMode() -> Bool {
	let env = ProcessInfo.processInfo.environment
	if env["XCTestConfigurationFilePath"] != nil {
		return true
	}
	return false
}

protocol SynchronousDispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void)
}

extension DispatchQueue: SynchronousDispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void) {
		async(group: nil, qos: .unspecified, flags: [], execute: work)
	}
}

func currentTimeMillis() -> Int64 {
	  var darwinTime : timeval = timeval(tv_sec: 0, tv_usec: 0)
	  gettimeofday(&darwinTime, nil)
	  return (Int64(darwinTime.tv_sec) * 1000) + Int64(darwinTime.tv_usec / 1000)
}

func copyBundleFileToDocs(_ fileName: String) {
	let fileNameParts = fileName.split(separator: ".")
	let fileNamePrefix = String(fileNameParts[0])
	let fileNameSuffix = String(fileNameParts[1])
	let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		.first!.appendingPathComponent(fileNamePrefix).appendingPathExtension(fileNameSuffix)
	guard let bundleURL = Bundle.main.url(forResource: "TestCatalog", withExtension: "sqlite") else {
		fatalError("copyBundleFileToDocuments: failed to unwrap bundleURL")
	}
	do {
		try FileManager.default.removeItem(atPath: docsURL.path)
	} catch { }
	do {
		try FileManager.default.copyItem(at: bundleURL, to: docsURL)
	} catch {
		fatalError("copyBundleFileToDocuments: failed to copy bundle file")
	}
}
