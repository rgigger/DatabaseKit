//
//  File.swift
//  
//
//  Created by Rick Gigger on 12/8/19.
//

import Foundation

public protocol SimpleStore {
    associatedtype Collection: SimpleCollection
    func createCollection(_ name: String) throws
    func getCollection(_ name: String) throws -> Collection?
    func read<R>(_ transactionBlock: (Collection.Transaction) throws -> R) throws -> R
}
