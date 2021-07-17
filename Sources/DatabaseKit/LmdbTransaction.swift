//
//  File.swift
//
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation
import SwiftLMDB

// Once this is in it's own module maybe it should just be (Donegal.)Transaction
public class LmdbTransaction: SimpleTransaction {
    // this needs to be part of the protocol somehow, maybe?
    public enum Action {
        case abort, commit
        internal var mapped: Transaction.Action {
            switch self {
            case .abort: return .abort
            case .commit: return .commit
            }
        }
    }
    let transaction: Transaction
    public init(_ transaction: Transaction) throws {
        self.transaction = transaction
    }
}
