//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation
import SwiftLMDB

public class LmdbStore: SimpleStoreBase<LmdbCollection> {
    let environment: Environment
    public init(path: String) throws {
        environment = try Environment(path: path, flags: [], maxDBs: 32)
    }
    override public func newCollection(name: String) throws -> LmdbCollection {
        return try LmdbCollection(name: name, environment: environment)
    }
    public func read(transactionBlock: (LmdbTransaction) -> LmdbTransaction.Action) throws {
        try environment.read(transactionBlock: { (swiftLMDBTransaction) throws -> Transaction.Action in
            let lmdbTransaction = try LmdbTransaction(swiftLMDBTransaction)
            let result = transactionBlock(lmdbTransaction)
            return result.mapped
        })
    }
        
    public func write(transactionBlock: (LmdbTransaction) -> LmdbTransaction.Action) throws {
        try environment.write(transactionBlock: { (swiftLMDBTransaction) throws -> Transaction.Action in
            let lmdbTransaction = try LmdbTransaction(swiftLMDBTransaction)
            let result = transactionBlock(lmdbTransaction)
            return result.mapped
        })
   }
}
