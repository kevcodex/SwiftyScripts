//
//  VersionExecutable.swift
//  Source
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation
import ScriptHelpers

struct VersionExecutable: Executable {
    
    var argumentName: String {
        return "-v"
    }
    
    var description: String {
        return "Shows the current version"
    }
    
    let version: String
    
    init(version: String) {
        self.version = version
    }
    
    func run(arguments: [String]?) {
        Console.writeMessage("Current Version: \(version)")
    }
}
