//
//  UserArgument.swift
//  Source
//
//  Created by Kevin Chen on 2/20/19.
//

import Foundation

/// E.g. -u kchen@phunware.com
struct UserArgument: Argument {
    static var argumentName: String {
        return "u"
    }
    
    var description: String {
        return "The current user's email"
    }
    
    var requiresValue: Bool {
        return true
    }
    
    var value: String?
}
