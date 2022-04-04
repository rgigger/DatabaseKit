//
//  File.swift
//  
//
//  Created by Rick Gigger on 2/3/20.
//

import Foundation

public protocol SimpleTransaction {
    associatedtype Action: SimpleTransactionAction
}

public protocol SimpleTransactionAction {}


