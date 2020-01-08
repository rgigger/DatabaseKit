//
//  File.swift
//  
//
//  Created by Rick Gigger on 12/8/19.
//

import Foundation

open class BaseIndex {
    var name: String
    var store: SimpleStore
    var collection: SimpleCollection
    public init(_ name: String, store: SimpleStore) throws {
        self.name = name
        self.store = store
        try self.store.createCollection(name)
        try self.collection = self.store.getCollection(name)!
    }
    public func get(_ key: String) throws -> String? {
        guard let loaded = try self.collection.get(key: key) else { return nil }
        return String(data: loaded, encoding: .utf8)
    }
    public func set(key: String, value: String) throws {
        // it is supposedly safe to do a force unwrap here as long as the encoding is .utf8
        try self.collection.set(key: key, data: value.data(using: .utf8)!)
    }
    public func delete(key: String) throws {
        try self.collection.delete(key: key)
    }
}
