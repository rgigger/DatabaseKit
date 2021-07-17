//
//  File.swift
//  
//
//  Created by Rick Gigger on 7/10/21.
//

import Foundation

public protocol LargeObjectCollection {
    associatedtype Transaction: LargeObjectTransaction
    func upload(key: String, fromSource: URL, withTransaction transaction: Transaction?) throws
    func download(key: String, toDestination: URL, withTransaction transaction: Transaction?) throws
    func delete(key: String, withTransaction transaction: Transaction?) throws
}
