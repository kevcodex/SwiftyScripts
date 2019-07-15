//
//  HelpDescription.swift
//  
//
//  Created by Kevin Chen on 7/9/19.
//

import Foundation
import ScriptHelpers

protocol HelpDescription {
    var argumentName: String { get }
    /// The description that will display in help
    var description: String { get }
}

extension HelpDescription where Self: Argument {
    var argumentName: String {
        return Self.argumentName
    }
}

// terminal will conform
// each exexcutable will conform to help deisplyable whil arguments are just help descriptions
// maybe have a helpdescription and a helpdisplayable
protocol HelpDisplayable: HelpDescription {
    func showHelp(for arguments: [HelpDescription])
}

extension HelpDisplayable where Self: Executable {
    func showHelp(for arguments: [HelpDescription]) {
        var argumentsString: String = ""
        
        for argument in arguments {
            let count = argument.argumentName.count
            let whiteSpaceCount = 15 - count
            let whiteSpaces = repeatElement(" ", count: whiteSpaceCount).joined()
            argumentsString += "   \(argument.argumentName)\(whiteSpaces)\(argument.description) \n"
        }
        
        Console.writeMessage(
            """
            COMMAND: \(argumentName)
            
            DESCRIPTION: \(description)
            
            OPTIONS:
            \(argumentsString)
            """
        )
    }
}

