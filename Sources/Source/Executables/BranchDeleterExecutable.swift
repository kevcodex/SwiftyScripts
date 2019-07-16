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
        
        let configPath = currentDirectory + "/swiftyscripts/config/config.plist"
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            Console.writeMessage("Directory does not have config, please create a config at path '/swiftyscripts/config/config.plist'.", styled: .red)
            Darwin.exit(1)
        }
        
        let url = URL(fileURLWithPath: configPath)
        
        guard let purgerConfig = SetupHelper.createPurgerConfig(from: url) else {
            Console.writeMessage("Something went wrong parsing purger config", styled: .red)
            Darwin.exit(1)
        }
        
        // MARK: Get all branches
        Console.writeMessage("**Getting all branches")
        let getAllRemoteBranchesCommand =
        """
        git branch -r | grep \(purgerConfig.branchFolder)| sed "s/origin\\///g"
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
        
        guard var branchContexts = branches.nonEmpty else {
            Console.writeMessage("Empty list of branches", styled: .red)
            Darwin.exit(1)
        }
        
        // MARK: Check Status
        Console.writeMessage("**Checking Status of branches")
        let credentials = JIRACredentials(email: purgerConfig.jira.email,
                                          password: purgerConfig.jira.password)
        let jiraController = JIRAController(credentials: credentials)
        
        jiraController.checkStatus(for: &branchContexts,
                                   baseURL: purgerConfig.jira.url,
                                   closedStatus: purgerConfig.jira.closedStatus ?? "Closed")
        
        for branch in branchContexts {
            
            guard branch.ticketIsClosed else {
                continue
            }
            
            // MARK: Checkout Branch
            Console.writeMessage("**Checking out \(branch.branchName)...")
            let checkoutCommand = GitCommand(arguments: [.checkout(branch: branch.branchName)])
            CommandHelper.runCommand(checkoutCommand)
            
            // MARK: Delete Branch
            Console.writeMessage("**Deleting \(branch.branchName)...")
            let deleteRemote = GitCommand(arguments: [.deleteRemote(branch: branch.branchName)])
            
            // TODO: In future rather than stop app if failure, just save that it failed and print in final message
            CommandHelper.runCommand(deleteRemote)
        }
        
        // TODO: In future show list of branches deleted or not deleted
        Console.writeMessage("Success! Finished Purging Branches!", styled: .green)
    }
}
