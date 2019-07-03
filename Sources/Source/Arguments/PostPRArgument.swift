//
//  PostPRArgument.swift
//  Run
//
//  Created by Kevin Chen on 7/16/18.
//

import Foundation

/// Argument to define if script should only run the post PR part
struct PostPRArgument: Argument {
    static var argumentName: String {
        return "post-only"
    }
    
    var requiresValue: Bool {
        return false
    }
    
    var value: String?
}
