//
//  Executable.swift
//  Run
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation

/// Arguments that execute something.
protocol Executable: HelpDisplayable {    
    func run(arguments: [String]?)
}
