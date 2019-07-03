//
//  BuildExecutable.swift
//  
//
//  Created by Kevin Chen on 7/1/19.
//

import Foundation
import ScriptHelpers

struct BuildExecutable: Executable {
    var argumentString: String {
        return "build"
    }
    
    func run(arguments: [String]?) {
        // MARK: Define and Parse Arguments

        let directoryArgument = DirectoryArgument()
        let prettyArgument = PrettyArgument()
        
        let argumentDictionary: [String: Argument] =
            [DirectoryArgument.argumentName: directoryArgument,
             PrettyArgument.argumentName: prettyArgument
        ]
        
        let argumentParser = ArgumentParser(argumentsToParse: argumentDictionary)
        do {
            try argumentParser.parse(inputs: CommandLine.arguments)
        } catch ArgumentParser.ParserError.unknownArgument(let input) {
            // nothing For now
            Console.writeMessage("Undefined argument: \(input). You may need to define in Argument Parser", styled: .red)
            Darwin.exit(1)
        } catch ArgumentParser.ParserError.missingValue(let argument) {
            Console.writeMessage("Missing value for argument: \(argument)", styled: .red)
            Darwin.exit(1)
        } catch {
            Console.writeMessage("Unknown Error: \(error)", styled: .red)
            Darwin.exit(1)
        }
        
        var runPretty = false
        if let _: PrettyArgument = argumentParser.retrieveArgument(string: PrettyArgument.argumentName) {
            
            if let prettyCheckCommand = AnyCommand(rawStringInput: "which xcpretty"),
                CommandHelper.runCommandSilently(prettyCheckCommand) {
                runPretty = true
            } else {
                Console.writeMessage("It doesn't seem you have xcpretty installed! You can install with \"gem install xcpretty\"", styled: .red)
                Darwin.exit(1)
            }
        }
        
        var currentDirectory = FileManager.default.currentDirectoryPath
        if let directoryArgument: DirectoryArgument = argumentParser.retrieveArgument(string: DirectoryArgument.argumentName),
            let directoryValue = directoryArgument.value  {
            currentDirectory = directoryValue
            
            CommandHelper.changeDirectory(to: currentDirectory)
        }
        
        let foxNowPath = currentDirectory + "/FOXNOW.xcodeproj"
        guard FileManager.default.fileExists(atPath: foxNowPath) else {
            Console.writeMessage("Path: \(foxNowPath) does not contain FOXNOW project.", styled: .red)
            Darwin.exit(1)
        }
        
        // MARK: Retrieve Plist
        // If running from xcode make sure to set custom working path in edit scheme -> options
        
        let configPath = currentDirectory + "/swiftyscripts/config/config.plist"
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            Console.writeMessage("Directory does not have config, please create a config at path '/swiftyscripts/config/config.plist'.", styled: .red)
            Darwin.exit(1)
        }
        
        let url = URL(fileURLWithPath: configPath)
        let dictionary = NSDictionary(contentsOf: url) as? [String: Any]
        
        // MARK: Define Targets
        guard let targetsToRun = SetupHelper.createTargets(from: dictionary) else {
            Console.writeMessage("Skewed, missing, or unspecified target type", styled: .red)
            Darwin.exit(1)
        }
        
        run(targetsToRun: targetsToRun, runPretty: runPretty)
    }
    
    func run(targetsToRun: [String], runPretty: Bool) {
        // Build all targets
        for target in targetsToRun {
            
            Console.writeMessage("**Building \(target)...")
            // xcodebuild -workspace FOXNOW.xcworkspace -configuration QA -scheme NatGeo -sdk appletvos11.2
            let buildCommand = XcodeBuildCommand(arguments: [.workspace(named: "FOXNOW.xcworkspace"),
                                                             .sdk(type: .tvOSSimulator),
                                                             .configuration(type: .qa),
                                                             .scheme(named: target),
                                                             .clean,
                                                             .build,
                                                             .modernSystem(shouldUse: false)])
            
            if runPretty,
                let xcprettyRun = AnyCommand(rawStringInput: buildCommand.commandAsString() + " " + "| xcpretty && exit ${PIPESTATUS[0]}") {
                
                CommandHelper.runAndPrintBashCommand(xcprettyRun)
            } else {
                CommandHelper.runAndPrintCommand(buildCommand)
            }
        }
    }
}
