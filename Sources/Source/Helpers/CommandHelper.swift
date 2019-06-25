//
//  MethodHelpers.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 4/13/18.
//

import Foundation
import ScriptHelpers

/// A helper that will run generic commands
struct CommandHelper {
    
    static func changeDirectory(to path: String) {
        let finalPath = path.replacingOccurrences(of: "\\", with: "")
        do {
            try shell.changeCurrentDirectory(to: finalPath)
        } catch {
            Console.writeMessage("Error: \(error)", styled: .red)
            exit(1)
        }
    }
    
    /// Run a command that will display a standard success or error message
    static func runCommand<C: Command>(_ command: C) {
        command.run() { result in
            
            switch result {
            case .success(let message):
                Console.writeMessage("Command Ran Successfully - " + message + "\n", styled: .blue)
            case .failure(let error):
                
                Console.writeMessage("Error: \(error)", styled: .red)
                exit(1)
            }
        }
    }
    
//    static func runBashCommand<C: Command>(_ command: C) {
//        command.runBash() { result in
//            switch result {
//            case .success(let message):
//                Console.writeMessage("Command Ran Successfully - " + message + "\n", styled: .blue)
//            case .failure(let error):
//                Console.writeMessage("Error: \(error.code) - " + error.message, styled: .red)
//                exit(1)
//            }
//        }
//    }
    
    /// Run a command silently and return the status
    static func runCommandSilently<C: Command>(_ command: C) -> Bool {
        
        var didSucceed = false
        command.run() { result in
            switch result {
            case .success:
                didSucceed = true
            case .failure:
                didSucceed = false
            }
        }
        
        return didSucceed
    }
    
    static func runAndPrintCommand<C: Command>(_ command: C) {
        command.runAndPrint() { result in
            switch result {
            case .success:
                Console.writeMessage("Command Ran Successfully! \n", styled: .blue)
            case .failure(let error):
                Console.writeMessage("Error: \(error)", styled: .red)
                exit(1)
            }
        }
    }
    
    static func runAndPrintCommand<C: Command>(_ command: C, completion: (Result<Void, RunError>) -> Void) {
        command.runAndPrint() { result in
            completion(result)
        }
    }
    
    static func runAndPrintBashCommand<C: Command>(_ command: C) {
        command.runAndPrintBash() { result in
            switch result {
            case .success:
                Console.writeMessage("Command Ran Successfully! \n", styled: .blue)
            case .failure(let error):
                Console.writeMessage("Error: \(error)", styled: .red)
                exit(1)
            }
        }
    }
}

