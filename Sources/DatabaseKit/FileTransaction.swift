//
//  File.swift
//
//
//  Created by Rick Gigger on 1/7/20.
//

import Foundation


public class FileTransaction: SimpleTransaction {
    // this needs to be part of the protocol somehow, maybe?
    public enum Action {
        case abort, commit
    }
}
