//
//  File.swift
//  
//
//  Created by Rick Gigger on 12/8/19.
//

import Foundation

public protocol SimpleStore {
    func createCollection(_ name: String)
    func getCollection(_ name: String) -> SimpleCollection?
}

public class MemoryStore: SimpleStore {
    var collections: [String:SimpleCollection] = [:]
    var collectionNames: [String] {
        get {
            return Array(self.collections.keys)
        }
    }
    public func createCollection(_ name: String) {
        if(self.collections[name] != nil) { return }
        self.collections[name] = DictCollection(name)
    }
    public func getCollection(_ name: String) -> SimpleCollection? {
        return self.collections[name]
    }
    public init() {}
}
