//
//  TextFile.swift
//  SportSearch
//  Created by Rick Tyler
//
//  Opens and/or loads/overwrites a text file in Documents directory given remote or local URL.
//  Allows line-by-line processing via Sequence protocol. Local paths assumed relative to app bundle
//  root.
//

import Foundation

class TextFile : Identifiable, Sequence {
	private var fileURL: URL
	fileprivate var file: UnsafeMutablePointer<FILE>?
	
	init(_ named: String ) {
		self.fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(named)
	}
	
	var size: UInt64 {
		return fileURL.fileSize   // see URL extension below
	}
	
	func fetch(_ uri: String, completionHandler: @escaping (Bool, String) -> Void) {
		let uriParts = uri.split(separator: ":")
		let url: URL
		if uriParts.count > 1, uriParts[0] == "http" || uriParts[0] == "https" || uriParts[0] == "file" {
			url = URL(string: uri)!
		} else {
			// assume local file in app bundle
			let fileNameParts = uri.split(separator: ".")
			let name = String(fileNameParts[0])
			let ext = String(fileNameParts[1])
			url = Bundle.main.url(forResource: name, withExtension: ext)!
		}
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		if let fileType = uri.split(separator: ".").last {
			request.setValue("text/\(fileType)", forHTTPHeaderField: "Accept")
		} else {
			request.setValue("text", forHTTPHeaderField: "Accept")
		}
		let sessionConfig = URLSessionConfiguration.default
		sessionConfig.timeoutIntervalForRequest = 10.0
		sessionConfig.timeoutIntervalForResource = 30.0
		let session = URLSession(configuration: sessionConfig)
		let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
			var errorString: String = ""
			var success = false
			defer {
				completionHandler(success, errorString)
			}
			if let error = error {
				errorString = "\(name(self)).fetch: generic error (\(error))"
				return
			}
			if let response = response as? HTTPURLResponse, response.statusCode != 200 {
				errorString = "\(name(self)).fetch: HTTP error (\(response.statusCode))"
				return
			}
			if let _ = data, let data = data, let _ = try? data.write(to: self.fileURL, options: Data.WritingOptions.atomic) {
				success = true
				self.file = nil
			} else {
				errorString = "\(name(self)).fetch: write() failed"
			}
		})
		task.resume()
	}
	
	public var nextLine: String? {
		if file == nil {
			file = fopen(fileURL.path, "r")
		}
		if file == nil {
			return nil
		}
		var line:UnsafeMutablePointer<CChar>? = nil
		var linecap:Int = 0
		defer { free(line) }
		let gotline = getline(&line, &linecap, file)
		let result = gotline > 0 ? String(cString: line!) : nil
		if result == nil {
			fclose(file)
		}
		return result?.trimmingCharacters(in: .newlines)
	}

	deinit {
		fclose(file)
	}
}

// MARK: Sequence conformance

extension TextFile {
	public func  makeIterator() -> AnyIterator<String> {
		return AnyIterator<String> {
			return self.nextLine
		}
	}
}

// MARK: URL extension returns file size

private extension URL {
	
	var attributes: [FileAttributeKey : Any]? {
		do {
			return try FileManager.default.attributesOfItem(atPath: path)
		} catch let error as NSError {
			print("FileAttribute error: \(error)")
		}
		return nil
	}

	var fileSize: UInt64 {
		return attributes?[.size] as? UInt64 ?? UInt64(0)
	}
}
