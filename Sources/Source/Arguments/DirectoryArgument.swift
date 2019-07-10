//
//  DirectoryArgument.swift
//  Run
//
//  Created by Kevin Chen on 7/17/18.
//

import Foundation

/// Set specific directory path to run merge. example: -dir /Downloads/app
struct DirectoryArgument: Argument {
    static var argumentName: String {
        return "dir"
    }
    
    var description: String {
        return "Sets the directory path to run the script"
    }
    
    var requiresValue: Bool {
        return true
    }
    
    var value: String?
}
