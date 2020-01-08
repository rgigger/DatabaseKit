//
//  File.swift
//  
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation
import SwiftLMDB

public class MemoryStore: BaseStore {
    override public func newCollection(name: String) -> SimpleCollection {
        return DictCollection(name)
    }
}
