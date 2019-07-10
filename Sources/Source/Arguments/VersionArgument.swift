//
//  VersionArgument.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 6/22/18.
//

import Foundation

/// example: -v 3.9
struct VersionArgument: Argument {
    static var argumentName: String {
        return "v"
    }
    
    var description: String {
        return "The version that you want to run a team merge on"
    }
    
    var requiresValue: Bool {
        return true
    }
    
    var value: String?
}

