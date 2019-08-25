//
//  File.swift
//  
//
//  Created by Rick Gigger on 8/25/19.
//

import Foundation

class BaseIndex {
    var name: String
    var store: SimpleStore
    var collection: SimpleCollection
    init(_ name: String, store: SimpleStore) {
        self.name = name
        self.store = store
        self.store.createCollection(name)
        self.collection = self.store.getCollection(name)!
    }
    func get(_ key: String) -> String? {
        guard let loaded = self.collection.get(key: key) else { return nil }
        return String(data: loaded, encoding: .utf8)
    }
    func set(key: String, value: String) {
        self.collection.set(key: key, data: value.data(using: .utf8)!)
    }
}


class BaseCollection<T: Codable> {
    var name: String
    var store: SimpleStore
    var collection: SimpleCollection
    init(_ name: String, store: SimpleStore) {
        self.name = name
        self.store = store
        self.store.createCollection(name)
        self.collection = self.store.getCollection(name)!
    }
    func get(_ key: String) -> T? {
        var record: T?
        do {
            guard let loaded = self.collection.get(key: key) else { return nil }
            record = try JSONDecoder().decode(T.self, from: loaded)
        } catch { print(error) }
        return record!
    }
    func set(key: String, value: T) {
        do {
            let json = try JSONEncoder().encode(value)
            self.collection.set(key: key, data: json)
        } catch { print(error) }
    }
    func getKey(forModel model: T) -> String {
        // This is a bad way of doing this. Ideally we would use an abstract method, but Swift doesn't support them.
        // In lieu of that we should probably at least throw here if this gets called
        return ""
    }
    func create(_ model: T) throws {
        let key = self.getKey(forModel: model)
        let old = self.get(key)
        guard old == nil else { throw DatabaseKitError.keyAlreadyExists(collection: self.name, key: key) }
        self.set(key: key, value: model)
    }
    // needs tests
    func updateOne(_ model: T) throws {
        let key = self.getKey(forModel: model)
        guard let _ = self.get(key) else { throw DatabaseKitError.keyNotFound(collection: self.name, key: key) }
        self.set(key: key, value: model)
    }
    // needs tests
    func createOrUpdateOne(_ model: T) throws {
        let key = self.getKey(forModel: model)
        // guard let _ = self.get(key) else { throw DatabaseKitError.keyNotFound(collection: self.name, key: key) }
        self.set(key: key, value: model)
    }
    func find(byKey key: String) throws -> T {
        guard let model = self.get(key) else { throw DatabaseKitError.keyNotFound(collection: self.name, key: key)}
        return model;
    }
    func find(_ filter: (String, T) -> Bool) -> [T] {
        var results: [T] = []
        self.collection.each { (key, data) in
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
