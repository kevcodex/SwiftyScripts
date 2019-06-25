//
//  AnyCommand.swift
//  TeamMergeAutomationPackageDescription
//
//  Created by Kevin Chen on 4/12/18.
//

import Foundation

/// One off general purpose commands that you input via String
struct AnyCommand: Command {

    typealias Argument = String
    
    let commandString: String
    let arguments: [String]
    
    init(commandString: String, arguments: [String]) {
        self.commandString = commandString
        self.arguments = arguments
    }
    
    /// Initialize a command from a full string input.
    /// E.g. "pod install --repo-update"
    init?(rawStringInput: String) {
        
        guard !rawStringInput.isEmpty else {
            return nil
        }
        
        let components = rawStringInput.components(separatedBy: " ")
        
        guard let commandString = components.first else {
            return nil
        }
        
        self.init(commandString: commandString, arguments: Array(components.dropFirst()))
    }
    
    func argumentsAsStringArray() -> [String] {
        return arguments
    }
    
    
}
