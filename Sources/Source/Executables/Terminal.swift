//
//  Terminal.swift
//  Source
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation
import ScriptHelpers

final class Terminal {
    func run(_ executables: [Executable], inputs: [String]) {
        var firstExecutable: Executable? = nil
        
        var arguments: [String]? = nil
        
        for (index, input) in inputs.enumerated() {
            if let executable = executables.first(where: { $0.argumentString == input }) {
                firstExecutable = executable
                
                arguments = Array(inputs[index..<inputs.count])
                break
            }
        }
        
        guard let executable = firstExecutable else {
            Console.showHelp()
            Console.writeMessage("No Commands", styled: .red)
            return
        }
        
        executable.run(arguments: arguments)
    }
}
