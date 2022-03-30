//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation
import SwiftLMDB

public class LmdbCollection: SimpleCollection {
    public typealias Transaction = LmdbTransaction
    let name: String
    let environment: Environment
    let database: Database
    init(name: String, environment: Environment) throws {
        self.name = name
        self.environment = environment
        self.database = try environment.openDatabase(named: name, flags: [.create])
    }
    public func set(key: String, data: Data, withTransaction optionalLmdbTransaction: Transaction?) throws {
        if let transaction = optionalLmdbTransaction?.transaction {
            try database.put(value: data, forKey: key, withTransaction: transaction)
        } else {
            try database.put(value: data, forKey: key)
        }
    }
    public func get(key: String, withTransaction optionalLmdbTransaction: Transaction?) throws -> Data? {
        if let transaction = optionalLmdbTransaction?.transaction {
            return try database.get(type: Data.self, forKey: key, withTransaction: transaction)
        } else {
            return try database.get(type: Data.self, forKey: key)
        }
    }
    public func delete(key: String, withTransaction optionalLmdbTransaction: Transaction?) throws {
        if let transaction = optionalLmdbTransaction?.transaction {
            try database.deleteValue(forKey: key, withTransaction: transaction)
        } else {
            try database.deleteValue(forKey: key)
        }

    }
    
    public func each(withTransaction optionalLmdbTransaction: Transaction?, _ cb: (String, Data) -> Bool) throws {
        
        func readEach(_ swiftLMDBTransaction: SwiftLMDBTransaction, _ callback: (String, Data) -> Bool) throws {
            for (keyData, valData) in try database.cursor(withTransaction: swiftLMDBTransaction) {
                let keyString = String(data: keyData)!
                _ = callback(keyString, valData)
            }
        }
        
        if let lmdbTransaction = optionalLmdbTransaction {
            try readEach(lmdbTransaction.transaction, cb)
        } else {
            try environment.read { (swiftLMDBTransaction) -> SwiftLMDBTransaction.Action in
                try readEach(swiftLMDBTransaction, cb)
                return .commit
            }
        }
    }
    public func empty() throws {
        try database.empty()
    }
}
