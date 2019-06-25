//
//  NoInputArgument.swift
//  Source
//
//  Created by Kevin Chen on 1/11/19.
//

import Foundation

/// if specified, then will not request user input
struct NoInputArgument: Argument {
    var argumentName: String {
        return "no-input"
    }
    
    var requiresValue: Bool {
        return false
    }
    
    var value: String?
}
