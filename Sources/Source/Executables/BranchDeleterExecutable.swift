//
//  BranchDeleterExecutable.swift
//  
//
//  Created by Kevin Chen on 7/12/19.
//

import Foundation
import ScriptHelpers

struct BranchDeleterExecutable: Executable {
    var argumentName: String {
        return "purger"
    }
    
    var description: String {
        return "Automatically delete branches based on a closed JIRA status"
    }
    
    func run(arguments: [String]?) {
        // Need to replace hardcoded grep with branch folder argument
        // Parse out config params
        // Create jira controller
        // Connect to JIRA API and check the status of that ticket
        // If a branch is closed, it should then first checkout the branch then delete the remote branch
        let arguments: [Argument] = [DirectoryArgument(),
                                     HelpArgument()]
        
        let argumentParser = parseArguments(arguments)
        
        if argumentParser.argumentsIsEmpty()  {
            showHelp(for: arguments)
            Console.writeMessage("Need to specify arguments like -v", styled: .red)
            Darwin.exit(1)
        }
        
        var currentDirectory = FileManager.default.currentDirectoryPath
        if let directoryArgument: DirectoryArgument = argumentParser.retrieveArgument(),
            let directoryValue = directoryArgument.value  {
            currentDirectory = directoryValue
            
            CommandHelper.changeDirectory(to: currentDirectory)
        }
        
        let getAllRemoteBranchesCommand =
        """
        git branch -r | grep entitlements/bugfix/* | sed "s/origin\\///g"
        """
        
        let jiraPrefixes = AnyCommand(rawStringInput: getAllRemoteBranchesCommand)
        
        var branches: [BranchContext] = []
        jiraPrefixes?.runBash(completion: { (result) in
            switch result {
                
            case .success(let string):
                
                let rawBranches = string.components(separatedBy: "\n").filter { !$0.isEmpty }
                branches = rawBranches.map { BranchContext(branchName: $0) }
            case .failure(let error):
                Console.writeMessage(error)
                Darwin.exit(1)
            }
        })
        
        guard let branchContexts = branches.nonEmpty else {
            Console.writeMessage("Empty list of branches", styled: .red)
            Darwin.exit(1)
        }
        
        
    }
}
