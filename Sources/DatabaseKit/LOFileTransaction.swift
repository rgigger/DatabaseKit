//
//  File.swift
//  
//
//  Created by Rick Gigger on 7/11/21.
//

import Foundation

public class LOFileTransaction: LargeObjectTransaction {
    public enum Action {
        case abort, commit
    }
}
