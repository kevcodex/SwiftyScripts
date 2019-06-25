//
//  UserArgument.swift
//  Source
//
//  Created by Kevin Chen on 2/20/19.
//

import Foundation

/// E.g. -u kchen@phunware.com
struct UserArgument: Argument {
    var argumentName: String {
        return "u"
    }
    
    var requiresValue: Bool {
        return true
    }
    
    var value: String?
}
