//
//  JenkinsOnlyArgument.swift
//  Source
//
//  Created by Kevin Chen on 12/28/18.
//

import Foundation

/// Argument to define if script should only run the jenkins build job
struct JenkinsOnlyArgument: Argument {
    var argumentName: String {
        return "jenkins-only"
    }
    
    var requiresValue: Bool {
        return false
    }
    
    var value: String?
}
