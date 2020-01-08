//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation

/// would it be possilbe/better to put this stuff into a protocol extension rather than using a base class?
public class BaseStore: SimpleStore {
    var collections: [String:SimpleCollection] = [:]
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
    public func newCollection(name: String) throws -> SimpleCollection {
        fatalError("newCollection is a virtual function, you must override it in the subclass")
    }
    public func getCollection(_ name: String) -> SimpleCollection? {
        self.collections[name]
    }
}
