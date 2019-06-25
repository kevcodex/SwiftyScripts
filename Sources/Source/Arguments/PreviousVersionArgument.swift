//
//  PreviousVersionArgument.swift
//  SwiftShell
//
//  Created by Kevin Chen on 6/26/18.
//

import Foundation

/// example: -pv 3.9
struct PreviousVersionArgument: Argument {
    var argumentName: String {
        return "pv"
    }

    var requiresValue: Bool {
        return true
    }
    
    var value: String?
}
