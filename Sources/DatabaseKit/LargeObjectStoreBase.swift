//
//  File.swift
//  
//
//  Created by Rick Gigger on 7/11/21.
//

import Foundation

public class LargeObjectStoreBase<Collection: LargeObjectCollection>: LargeObjectStore {
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
}

