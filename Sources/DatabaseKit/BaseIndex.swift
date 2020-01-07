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
    public init(_ name: String, store: SimpleStore) {
        self.name = name
        self.store = store
        self.store.createCollection(name)
        self.collection = self.store.getCollection(name)!
    }
    public func get(_ key: String) -> String? {
        guard let loaded = self.collection.get(key: key) else { return nil }
        return String(data: loaded, encoding: .utf8)
    }
    public func set(key: String, value: String) {
        // it is supposedly safe to do a force unwrap here as long as the encoding is .utf8
        self.collection.set(key: key, data: value.data(using: .utf8)!)
    }
    public func delete(key: String) {
        self.collection.delete(key: key)
    }
}
