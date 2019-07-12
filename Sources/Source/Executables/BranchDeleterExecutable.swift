//
//  BranchDeleterExecutable.swift
//  
//
//  Created by Kevin Chen on 7/12/19.
//

import Foundation

struct BranchDeleterExecutable: Executable {
    var argumentName: String {
        return "purger"
    }
    
    var description: String {
        return "Automatically delete branches based on a closed JIRA status"
    }
    
    func run(arguments: [String]?) {
        // Config needs a project URL and branch folder and JIRA url/anything jira related
        // fetch all branches in desired branch folder.
        // Since it will return as a string, need to seperate each branch into array
        // Need to use regex to only get the JIRA
        // Connect to JIRA API and check the status of that ticket
        // If a branch is closed, it should then first checkout the branch then delete the remote branch
        let arguments: [Argument] = [DirectoryArgument(),
                                     HelpArgument()]
        
        let argumentParser = parseArguments(arguments)
    }
}
