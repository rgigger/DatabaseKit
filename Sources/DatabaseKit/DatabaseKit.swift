//
//  main.swift
//  database-kit
//
//  Created by Rick Gigger on 8/15/19.
//  Copyright © 2019 Rick Gigger. All rights reserved.
//

import Foundation

public enum DatabaseKitError: Error, Equatable {
    case keyNotFound(collection: String, key: String)
    case keyAlreadyExists(collection: String, key: String)
    case shouldNeverHappen
}
