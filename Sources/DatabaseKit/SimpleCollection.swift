//
//  File.swift
//  
//
//  Created by Rick Gigger on 8/25/19.
//

import Foundation

public protocol SimpleCollection {
    associatedtype Transaction: SimpleTransaction
    func set(key: String, data: Data, withTransaction transaction: Transaction?) throws
    func get(key: String, withTransaction transaction: Transaction?) throws -> Data?
    func delete(key: String, withTransaction transaction: Transaction?) throws
    func each(withTransaction optionalSwiftLMDBTransaction: Transaction?, _ cb: (String, Data) -> Bool) throws
    func empty() throws
}
