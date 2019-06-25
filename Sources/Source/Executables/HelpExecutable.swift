//
//  HelpExecutable.swift
//  Source
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation
import ScriptHelpers

struct HelpExecutable: Executable {
    var argumentString: String {
        return "-help"
    }
    
    func run(arguments: [String]?) {
        Console.showHelp()
    }
}
