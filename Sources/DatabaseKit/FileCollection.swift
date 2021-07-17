//
//  File.swift
//  
//
//  Created by Rick Gigger on 4/1/21.
//

import Foundation

public class FileCollection: SimpleCollection {
    public typealias Transaction = FileTransaction
    let name: String
    init(name: String) throws {
        self.name = name
    }
    public func set(key: String, data: Data, withTransaction optionalFileTransaction: Transaction?) throws {
    }
    public func get(key: String, withTransaction optionalFileTransaction: Transaction?) throws -> Data? {
        return Data()
    }
    public func delete(key: String, withTransaction optionalFileTransaction: Transaction?) throws {
    }
    
    public func each(withTransaction optionalFileTransaction: Transaction?, _ cb: (String, Data) -> Bool) throws {
    }
    public func empty() throws {
    }
}
