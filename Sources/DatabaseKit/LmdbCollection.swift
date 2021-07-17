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
        try database.put(value: data, forKey: key, withTransaction: optionalLmdbTransaction?.transaction)
    }
    public func get(key: String, withTransaction optionalLmdbTransaction: Transaction?) throws -> Data? {
        return try database.get(type: Data.self, forKey: key, withTransaction: optionalLmdbTransaction?.transaction)
    }
    public func delete(key: String, withTransaction optionalLmdbTransaction: Transaction?) throws {
        try database.deleteValue(forKey: key, withTransaction: optionalLmdbTransaction?.transaction)
    }
    
    public func each(withTransaction optionalLmdbTransaction: Transaction?, _ cb: (String, Data) -> Bool) throws {
        
        func readEach(_ swiftLMDBTransaction: SwiftLMDB.Transaction, _ callback: (String, Data) -> Bool) throws {
            let cursor = try database.createCursor(transaction: swiftLMDBTransaction)
            var (keyData, valData) = try cursor.first()
            while let kd = keyData, let vd = valData {
                let keyString = String(data: kd)!
                _ = callback(keyString, vd)
                (keyData, valData) = try cursor.next()
            }
        }
        
        if let lmdbTransaction = optionalLmdbTransaction {
            try readEach(lmdbTransaction.transaction, cb)
        } else {
            try environment.read { (swiftLMDBTransaction) -> SwiftLMDB.Transaction.Action in
                try readEach(swiftLMDBTransaction, cb)
                return .commit
            }
        }
    }
    public func empty() throws {
        try database.empty()
    }
}
