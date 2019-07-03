//
//  PrettyArgument.swift
//  Run
//
//  Created by Kevin Chen on 11/7/18.
//

import Foundation

/// example: -pretty
struct PrettyArgument: Argument {
    static var argumentName: String {
        return "pretty"
    }
    
    var requiresValue: Bool {
        return false
    }
    
    var value: String?
}
