//
//  ArgumentType.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 6/25/18.
//

import Foundation

// Unused
@available(*, deprecated, message: "Parse arguments using string instead")
enum ArgumentType: String, Equatable {
    
    case version
    case previousVersion
    case postPR
    case jenkinsOnly
    case directory
    case pretty
    case unknown
    
//    init(string: String) {
//        
//        var type = ArgumentType.unknown
//        
//        switch string {
//            
//        case VersionArgument.argumentString:
//            type = .version
//            
//        case PreviousVersionArgument.argumentString:
//            type = .previousVersion
//            
//        case PostPRArgument.argumentString:
//            type = .postPR
//            
//        case JenkinsOnlyArgument.argumentString:
//            type = .jenkinsOnly
//            
//        case DirectoryArgument.argumentString:
//            type = .directory
//            
//        case PrettyArgument.argumentString:
//            type = .pretty
//            
//        default:
//            break
//        }
//        
//        self = type
//    }
}
