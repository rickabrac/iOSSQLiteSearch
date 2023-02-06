//
//  DispatchQueue.swift
//  SportSearch
//  Created by Rick Tyler
//

import Foundation

protocol SynchronousDispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void)
}

extension DispatchQueue: SynchronousDispatchQueue {
	func execute(execute work: @escaping @convention(block) () -> Void) {
		async(group: nil, qos: .unspecified, flags: [], execute: work)
	}
}
