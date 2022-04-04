//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation

public class SimpleStoreBase<Collection: SimpleCollection>: SimpleStore {

    var collections: [String:Collection] = [:]
    var collectionNames: [String] {
        get {
            return Array(self.collections.keys)
        }
    }
    public init() {}
    public func createCollection(_ name: String) throws {
        if(self.collections[name] != nil) { return }
        self.collections[name] = try newCollection(name: name)
    }
    public func newCollection(name: String) throws -> Collection {
        fatalError("newCollection is a virtual function, you must override it in the subclass")
    }
    public func getCollection(_ name: String) -> Collection? {
        self.collections[name]
    }

    public func read<R>(_ transactionBlock: (Collection.Transaction) throws -> R) throws -> R {
        preconditionFailure("This method must be overridden")
    }
}

