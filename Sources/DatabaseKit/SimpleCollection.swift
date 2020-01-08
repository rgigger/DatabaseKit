//
//  File.swift
//  
//
//  Created by Rick Gigger on 8/25/19.
//

import Foundation

public protocol SimpleCollection {
    func set(key: String, data: Data) throws
    func get(key: String) throws -> Data?
    func delete(key: String) throws
    func each(_ cb: (String, Data) -> Bool) throws
}
