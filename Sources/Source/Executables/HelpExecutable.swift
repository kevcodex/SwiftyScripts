//
//  HelpExecutable.swift
//  Source
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation
import ScriptHelpers

struct HelpExecutable: Executable {
    
    var argumentName: String {
        return "-help"
    }
    
    var description: String {
        return "Shows list of arguments and executables"
    }
    
    func run(arguments: [String]?) {
        // Empty since Terminal will display the help
    }
}
