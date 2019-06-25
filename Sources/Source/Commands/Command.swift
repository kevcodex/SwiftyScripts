//
//  Command.swift
//  CommandsTest
//
//  Created by Kevin Chen on 3/16/18.
//

import Foundation

let shell = Shell()

/// A shell command to execute
protocol Command {
    
    /// An argument type that will be used for building the list of arguments
    associatedtype Argument

    /// The bash command as a string
    var commandString: String { get }
    
    /// Array of all the arguments
    var arguments: [Argument] { get }
    
    /// Convert the arguments types to readable string format
    func argumentsAsStringArray() -> [String]
    
    /// Convert the command and arguments into a string
    func commandAsString() -> String
}

extension Command {
    func commandAsString() -> String {
        return commandString + " " + argumentsAsStringArray().joined(separator: " ")
    }
}

extension Command {
    func run(completion: @escaping (Result<String, RunError>) -> Void) {
        
        do {
            let output = try shell.run(commandString, argumentsAsStringArray())
            completion(Result(value: output))
        } catch {
            if let shellError = error as? ShellError {
                completion(Result(error: RunError.shellError(shellError)))
            } else {
                completion(Result(error: RunError.other(error)))
            }
        }
        
//        let runner = shell.run(commandString, argumentsAsStringArray())
//
//        if runner.succeeded {
//            completion(Result(value: runner.stdout))
//        } else {
//            let errorMessage = runner.stderror.isEmpty ? runner.stdout : runner.stderror
//            completion(Result(error: RunError(code: runner.exitcode, message: errorMessage)))
//        }
    }
    
    /// Run a bash script like "echo blah | grep blah"
//    func runBash(completion: @escaping (Result<String, RunError>) -> Void) {
//        let bash = commandAsString()
//        let runner = shell.run(bash: bash)
//
//        if runner.succeeded {
//            completion(Result(value: runner.stdout))
//        } else {
//            let errorMessage = runner.stderror.isEmpty ? runner.stdout : runner.stderror
//            completion(Result(error: RunError(code: runner.exitcode, message: errorMessage)))
//        }
//    }
//
    func runAndPrint(completion: (Result<Void, RunError>) -> Void) {
        do {
            try shell.runAndPrint(commandString, argumentsAsStringArray())
            completion(.success)
        } catch {
            if let shellError = error as? ShellError {
                completion(Result(error: RunError.shellError(shellError)))
            } else {
                completion(Result(error: RunError.other(error)))
            }
        }
    }
    
    func runAndPrintBash(completion: (Result<Void, RunError>) -> Void) {
        do {
            try shell.runAndPrintBash(commandAsString())
            completion(.success)
        } catch {
            if let shellError = error as? ShellError {
                completion(Result(error: RunError.shellError(shellError)))
            } else {
                completion(Result(error: RunError.other(error)))
            }
        }
    }
}
