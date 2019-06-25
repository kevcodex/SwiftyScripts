//
//  ArgumentParser.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 6/22/18.
//

import Foundation

/// The helper that parses out the inputs based on the defined arguments to parse
class ArgumentParser {
    
    /// Define the arguments you want the parser to parse
    private var argumentsToParse: [String: Argument]
    
    private var inputtedArgumentsDict: [String: Argument] = [:]
    
    init(argumentsToParse: [String: Argument]) {
        
        self.argumentsToParse = argumentsToParse
    }
    
    /// This will parse out the inputted values and append the value to the argument if needed.
    ///
    /// - throws:
    ///    `ArgumentParser.unknownArgument(input: String)` if it parses out an unknown argument.
    ///    `ArgumentParser.missingArgumentInParser(type: ArgumentType)` if it parses out an argument that has not been defined in the parser.
    ///    `ArgumentParser.missingValue(argument: Argument)` if the value is missing from an argument that requires a value.
    func parse(inputs: [String]) throws {
        
        for (index, inputArgument) in inputs.enumerated() {
            if inputArgument.first == "-" {
                
                let rawInputString = String(inputArgument.dropFirst())
                
                // Check if input is a defined argument to parse
                guard var argument = argumentsToParse[rawInputString] else {
                    throw ParserError.unknownArgument(input: rawInputString)
                }
                
                // Retrieve the value/parameter for argument
                if !argument.requiresValue {
                    inputtedArgumentsDict[rawInputString] = argument
                    continue
                }
                
                let nextIndex = index + 1
                guard inputs.indices.contains(nextIndex),
                    !inputs[nextIndex].isEmpty else {
                    throw ParserError.missingValue(argument: argument)
                }
                
                let value = inputs[nextIndex]
                argument.value = value
                
                inputtedArgumentsDict[rawInputString] = argument
            }
        }
    }
    
    func retrieveArgument<T>(string: String) -> T? where T: Argument {
        return inputtedArgumentsDict[string] as? T
    }
    
    func argumentsIsEmpty() -> Bool {
        return inputtedArgumentsDict.isEmpty
    }
    
}

// MARK: - Parser error
extension ArgumentParser {
    enum ParserError: Error {
        case unknownArgument(input: String)
        case missingValue(argument: Argument)
        case unknownError(message: String)
    }
}
