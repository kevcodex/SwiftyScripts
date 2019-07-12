//
//  Executable.swift
//  Run
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation
import ScriptHelpers

/// Arguments that execute something.
protocol Executable: HelpDisplayable {    
    func run(arguments: [String]?)
}

extension Executable {
    func parseArguments(_ arguments: [Argument]) -> ArgumentParser {
        
        let argumentDictionary = arguments.reduce(into: [String: Argument]()) { (result, argument) in
            result[argument.argumentName] = argument
        }
        
        let argumentParser = ArgumentParser(argumentsToParse: argumentDictionary)
        do {
            try argumentParser.parse(inputs: CommandLine.arguments)
        } catch ArgumentParser.ParserError.unknownArgument(let input) {
            showHelp(for: arguments)
            Console.writeMessage("Undefined argument: \(input). You may need to define in Argument Parser", styled: .red)
            Darwin.exit(1)
        } catch ArgumentParser.ParserError.missingValue(let argument) {
            showHelp(for: arguments)
            Console.writeMessage("Missing value for argument: \(argument)", styled: .red)
            Darwin.exit(1)
        } catch {
            showHelp(for: arguments)
            Console.writeMessage("Unknown Error: \(error)", styled: .red)
            Darwin.exit(1)
        }
        
        if let _: HelpArgument = argumentParser.retrieveArgument() {
            showHelp(for: arguments)
            Darwin.exit(0)
        }
        
        return argumentParser
    }
}
