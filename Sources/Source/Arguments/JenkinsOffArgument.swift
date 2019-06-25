//
//  JenkinsOffArgument.swift
//  Source
//
//  Created by Kevin Chen on 1/7/19.
//

import Foundation

/// Argument to define if script should not run jenkins
struct JenkinsOffArgument: Argument {
    var argumentName: String {
        return "jenkins-off"
    }
    
    var requiresValue: Bool {
        return false
    }
    
    var value: String?
}
