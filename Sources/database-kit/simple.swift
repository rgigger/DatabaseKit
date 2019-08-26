//
//  File.swift
//  
//
//  Created by Rick Gigger on 8/25/19.
//

import Foundation

class SimpleStore {
    var collections: [String:SimpleCollection] = [:]
    var collectionNames: [String] {
        get {
            return Array(self.collections.keys)
        }
    }
    func createCollection(_ name: String) {
        if(self.collections[name] != nil) { return }
        self.collections[name] = SimpleCollection(name)
    }
    func getCollection(_ name: String) -> SimpleCollection? {
        return self.collections[name]
    }
}

class SimpleCollection {
    let name: String
    var docs: [String:Data] = [:]
    init(_ name: String) {
        self.name = name
    }
    func set(key: String, data: Data) {
        self.docs[key] = data
    }
    func get(key: String) -> Data? {
        return self.docs[key]
    }
    @discardableResult func delete(key: String) -> Data? {
        return self.docs.removeValue(forKey: key)
    }
    func each(_ cb: (String, Data) -> Bool) {
        for (key, data) in self.docs {
            let keepGoing = cb(key, data)
            if(!keepGoing) { break }
        }
    }
}
