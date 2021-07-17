//
//  File.swift
//  
//
//  Created by Rick Gigger on 7/11/21.
//

import Foundation

public protocol LargeObjectStore {
    associatedtype Collection: LargeObjectCollection
    func createCollection(_ name: String) throws
    func getCollection(_ name: String) throws -> Collection?
}
