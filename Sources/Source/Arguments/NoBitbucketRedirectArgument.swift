//
//  NoBitbucketRedirectArgument.swift
//  Source
//
//  Created by Kevin Chen on 1/16/19.
//

import Foundation

struct NoBitbucketRedirectArgument: Argument {
    static var argumentName: String {
        return "no-bitbucket"
    }
    
    var requiresValue: Bool {
        return false
    }
    
    var value: String?
}
