//
//  File.swift
//  
//
//  Created by Rick Gigger on 12/8/19.
//

import Foundation

public protocol SimpleStore {
    func createCollection(_ name: String) throws
    func getCollection(_ name: String) throws -> SimpleCollection?
}
