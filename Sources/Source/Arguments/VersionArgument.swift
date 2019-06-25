//
//  VersionArgument.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 6/22/18.
//

import Foundation

/// example: -v 3.9
struct VersionArgument: Argument {
    var argumentName: String {
        return "v"
    }
    
    var requiresValue: Bool {
        return true
    }
    
    var value: String?
}

