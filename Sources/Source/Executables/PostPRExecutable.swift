//
//  PostPRExecutable.swift
//  
//
//  Created by Kevin Chen on 7/9/19.
//

import ScriptHelpers
import Foundation

struct PostPRExecutable: Executable {
    
    var argumentName: String {
        return "post-only"
    }
    
    var description: String {
        return "Only executes the post-PR portion of the team merge"
    }
    
    func run(arguments: [String]?) {
        // MARK: Define and Parse Arguments
        let versionArgument = VersionArgument()
        let directoryArgument = DirectoryArgument()
        
        let argumentDictionary: [String: Argument] =
            [VersionArgument.argumentName: versionArgument,
             DirectoryArgument.argumentName: directoryArgument
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
        
        guard let versionArg: VersionArgument = argumentParser.retrieveArgument(),
            let version = versionArg.value else {
                Console.writeMessage("Skewed or no version specified", styled: .red)
                Darwin.exit(1)
        }
        
        var currentDirectory = FileManager.default.currentDirectoryPath
        if let directoryArgument: DirectoryArgument = argumentParser.retrieveArgument(),
            let directoryValue = directoryArgument.value  {
            currentDirectory = directoryValue
            
            CommandHelper.changeDirectory(to: currentDirectory)
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
        
        // MARK: Define Branches
        let releaseBranch = Branch(type: .release, version: version)
        guard let developBranchesToRun = SetupHelper.createBranches(from: dictionary, version: version) else {
            Console.writeMessage("Skewed, missing, or unspecified branch type", styled: .red)
            Darwin.exit(1)
        }
        
        run(developBranchesToRun: developBranchesToRun, releaseBranch: releaseBranch)
    }
    
    func run(developBranchesToRun: [Branch], releaseBranch: Branch) {
        
        // MARK: Remove any local change anomolies
        Console.writeMessage("**Discarding Potential Local Changes...")
        let discardCommand = GitCommand(arguments: [.reset])
        CommandHelper.runCommand(discardCommand)
        
        // MARK: Fetch
        Console.writeMessage("**Fetching...")
        let fetchCommand = GitCommand(arguments: [.fetchAll])
        CommandHelper.runCommand(fetchCommand)
        
        for branch in developBranchesToRun {
            
            // MARK: Checkout
            Console.writeMessage("**Changing branch to \(branch.path)")
            let checkoutCommand = GitCommand(arguments: [.checkout(branch: branch.path)])
            CommandHelper.runCommand(checkoutCommand)
            
            // MARK: Pull Self
            Console.writeMessage("**Pulling \(branch.path)...")
            var pullCommand = GitCommand(arguments: [.pull(branch: nil)])
            CommandHelper.runCommand(pullCommand)
            
            // MARK: Pull from Release
            Console.writeMessage("**Pulling from \(releaseBranch.path)...")
            pullCommand = GitCommand(arguments: [.pull(branch: releaseBranch.path)])
            CommandHelper.runCommand(pullCommand)
            
            // MARK: Push
            Console.writeMessage("**Pushing \(branch.path)...")
            let pushCommand = GitCommand(arguments: [.push])
            CommandHelper.runCommand(pushCommand)
            
        }
        
        Console.writeMessage("Success! Finished Team Merge! You owe Kevin 5,000,000 PC now", styled: .green)
    }
}
