//
//  File.swift
//
//
//  Created by Rick Gigger on 4/1/21.
//

import Foundation

public class FileStore: SimpleStoreBase<FileCollection> {
    let path: String
    public init(path: String) throws {
        self.path = path
    }
    override public func newCollection(name: String) throws -> FileCollection {
        return try FileCollection(name: name)
    }
    public func read(transactionBlock: (FileTransaction) -> FileTransaction.Action) throws {
    }
        
    public func write(transactionBlock: (LmdbTransaction) -> LmdbTransaction.Action) throws {
   }
}
