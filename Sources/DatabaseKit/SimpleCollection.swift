//
//  File.swift
//  
//
//  Created by Rick Gigger on 8/25/19.
//

import Foundation

public protocol SimpleCollection {
    // init(_ name: String)
    func set(key: String, data: Data)
    func get(key: String) -> Data?
    @discardableResult func delete(key: String) -> Data?
    func each(_ cb: (String, Data) -> Bool)
}

class DictCollection: SimpleCollection {
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
