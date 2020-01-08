//
//  File.swift
//  
//
//  Created by Rick Gigger on 8/25/19.
//

import Foundation

open class BaseCollection<T: Codable> {
    public typealias afterSetTrigger = (String, T, T?) -> Void
    var name: String
    var store: SimpleStore
    var collection: SimpleCollection
    var afterSetTriggers: [afterSetTrigger] = []
    public init(_ name: String, store: SimpleStore) throws {
        self.name = name
        self.store = store
        try self.store.createCollection(name)
        try self.collection = self.store.getCollection(name)!
    }
    // fixme: should we make get and set private??? Right now if they get used then no triggers will be fired
    //        and indexes won't be kept up to date
    //        we have tests using them that we should probably just nuke
    func get(_ key: String) throws -> T? {
        var record: T?
        guard let loaded = try self.collection.get(key: key) else { return nil }
        record = try JSONDecoder().decode(T.self, from: loaded)
        return record!
    }
    func set(key: String, value: T) throws {
        let json = try JSONEncoder().encode(value)
        try self.collection.set(key: key, data: json)
    }
    // fixme: What does @escaping do? Could this create a memory leak? Why do I need it here?
    public func addAfterSetTrigger(_ trigger: @escaping afterSetTrigger) {
        self.afterSetTriggers.append(trigger)
    }
    // question: does private simple protect this from being used outside this class or just outside the module???
    private func _set(key: String, value: T, oldValue: T?) throws {
        try self.set(key: key, value: value)
        for trigger in self.afterSetTriggers {
            trigger(key, value, oldValue)
        }
    }
    open func getKey(forModel model: T) -> String {
        // This is a bad way of doing this. Ideally we would use an abstract method, but Swift doesn't support them.
        // In lieu of that we should probably at least throw here if this gets called
        return ""
    }
    public func create(_ model: T) throws {
        let key = self.getKey(forModel: model)
        let old = try self.get(key)
        guard old == nil else { throw DatabaseKitError.keyAlreadyExists(collection: self.name, key: key) }
        try self._set(key: key, value: model, oldValue: nil)
    }
    // needs tests
    func updateOne(_ model: T) throws {
        let key = self.getKey(forModel: model)
        guard let old = try self.get(key) else { throw DatabaseKitError.keyNotFound(collection: self.name, key: key) }
        try self._set(key: key, value: model, oldValue: old)
    }
    // needs tests
    func createOrUpdateOne(_ model: T) throws {
        let key = self.getKey(forModel: model)
        let old = try self.get(key)
        try self._set(key: key, value: model, oldValue: old)
    }
    func find(byKey key: String) throws -> T {
        guard let model = try self.get(key) else { throw DatabaseKitError.keyNotFound(collection: self.name, key: key)}
        return model;
    }
    func find(_ filter: (String, T) -> Bool) throws -> [T] {
        var results: [T] = []
        try self.collection.each { (key, data) in
            do {
                let record = try JSONDecoder().decode(T.self, from: data)
                if filter(key, record) == true {
                    results.append(record)
                }
            } catch {
                debugPrint(error)
            }
            return true
        }
        return results
    }
}
