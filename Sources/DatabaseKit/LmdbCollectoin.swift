//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation
import SwiftLMDB

class LmdbCollection: SimpleCollection {
    let name: String
    let database: Database
    init(name: String, environment: Environment) throws {
        self.name = name
        self.database = try environment.openDatabase(named: name, flags: [.create])
    }
    func set(key: String, data: Data) throws {
        try database.put(value: data, forKey: key, withTransaction: nil)
    }
    func get(key: String) throws -> Data? {
        return try database.get(type: Data.self, forKey: key, withTransaction: nil)
    }
    func delete(key: String) throws {
        try database.deleteValue(forKey: key)
    }
    func each(_ cb: (String, Data) -> Bool) throws {
        // before this can be implemented cursor support needs to be added to SwiftLMDB
        fatalError("not implemented yet")
    }
}
