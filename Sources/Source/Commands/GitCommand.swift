//
//  GitCommand.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 3/27/18.
//

import Foundation

struct GitCommand: Command {
    
    enum DiffOptions: String {
        case nameOnly = "--name-only"
    }
    
    enum GitType {
        case commit
        case addAll
        case status
        case message(message: String)
        case checkout(branch: String)
        case fetchAll
        case pull(branch: String?)
        case push
        case diff(branch1: String?, branch2: String, options: [DiffOptions])
        case reset
    }
    
    typealias Argument = GitType
    
    var commandString: String {
        return "git"
    }
    
    var arguments: [Argument]
    
    func argumentsAsStringArray() -> [String] {
        var string = ""
        
        for argument in arguments {
            switch argument {
            case .commit:
                string += "commit"
            case .addAll:
                string += "add ."
            case .status:
                string += "status"
            case .message(let message):
                // TODO: - Fix split so message doesn't get split up
                string += "-m '\(message)'"
            case .checkout(let branch):
                string += "checkout \(branch)"
            case .fetchAll:
                string += "fetch --all"
            case .pull(let branch):
                // If theres a specified branch pull from there otherwise pull self
                if let branch = branch {
                    string += "pull origin \(branch)"
                } else {
                    string += "pull"
                }
            case .push:
                string += "push"
            case .diff(let branch1, let branch2, let options):
                
                string += "diff "
                
                for option in options {
                    string += "\(option.rawValue) "
                }
                
                if let branch1 = branch1 {
                    string += "\(branch1)..\(branch2)"
                } else {
                    string += "..\(branch2)"
                }
            case .reset:
                string += "reset --hard"
            }
            
            string += " "
        }
        
        let stringArray = string.components(separatedBy: " ")
        let noEmptyStrings = stringArray.filter { !$0.isEmpty }
        
        return noEmptyStrings
    }
}
