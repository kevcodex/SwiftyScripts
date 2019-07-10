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
            if let executable = executables.first(where: { $0.argumentName == input }) {
                firstExecutable = executable
                
                arguments = Array(inputs[index..<inputs.count])
                break
            }
        }
        
        guard let executable = firstExecutable else {
            showHelp(for: executables)
            Console.writeMessage("No Commands", styled: .red)
            return
        }
        
        guard !(executable is HelpExecutable) else {
            showHelp(for: executables)
            return
        }
        
        executable.run(arguments: arguments)
    }
}

extension Terminal: HelpDisplayable {
    func showHelp(for arguments: [HelpDescription]) {
        var argumentsString: String = ""
        
        for argument in arguments {
            let count = argument.argumentName.count
            let whiteSapceCount = 15 - count
            let whiteSpaces = repeatElement(" ", count: whiteSapceCount).joined()
            argumentsString += "   \(argument.argumentName)\(whiteSpaces)\(argument.description) \n"
        }
        
        Console.writeMessage(
            """
            DESCRIPTION: \(description)

            USAGE: \(argumentName) [command] <options>
            
            COMMANDS:
            \(argumentsString)
            
            PLIST CONFIG:
                - Here is a list of all required and optional parameters. Unless specified the param is required. See Config in the project for an example.
            
                project (The xcode project to run)
            
                Jenkins (Required if you want to run jenkins)
                    - credentials
                        - email
                        - apiToken (Get from Jenkins)
                    - delayBetweenBuilds
                    - label
                        - prefix (The project name)
                        - numberOfConfigurations (The number of configurations that will deploy e.g. qa, uat, prod = 3)
                    - schemes (Array of each build scheme)
                - Each item
                    - target
                        - startBuildNumber (String, Optional, will override build number that is determined from jenkins)
                        - configuration (String, Optional, the CONFIGURATION param in jenkins)
                        - xcodeVersion (String, Optional, the XCODE_VERSION param in jenkins)
                        - shouldDeploy (Bool, Optional, the DEPLOY param in jenkins)
                        - shouldDistribute (Bool, Optional, the DISTRIBUTE param in jenkins)
                        - shouldReleaseDSYMS (Bool, Optional, the DSYMS param in jenkins)
                        - shouldReduceBuilds (Bool, Optional, the REDUCE_BUILDS param in jenkins)
                        - shouldNotifySlack (Bool, Optional, the NOTIFY_SLACK param in jenkins)
                        - isSubmissionCandidate (Bool, Optional, the SUBMISSION_CANDIDATE param in jenkins)
                        - knownIssues (String, Optional, the KNOWN_ISSUES param in jenkins)
            
                TargetsToRun (Array of each target in string)
                    - Each item (String)
            
                BranchesToRun (Array of each branch)
                    - Each item (String)
            """
        )
    }
    
    var argumentName: String {
        return "swiftyscripts"
    }
    
    var description: String {
        return "To help automate various processes"
    }
}
