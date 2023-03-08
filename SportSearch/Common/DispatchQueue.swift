//
//  DispatchQueue.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation

protocol _DispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void)
}

extension DispatchQueue: _DispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void) {
		async(group: nil, qos: .unspecified, flags: [], execute: work)
	}
}
