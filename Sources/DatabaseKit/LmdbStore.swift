//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation
import SwiftLMDB

public class LmdbStore: BaseStore {
    let environment: Environment
    public init(path: String) throws {
        environment = try Environment(path: path, flags: [], maxDBs: 32)
    }
    override public func newCollection(name: String) throws -> SimpleCollection {
        return try LmdbCollection(name: name, environment: environment)
    }
}
