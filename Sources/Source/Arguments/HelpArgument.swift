//
//  HelpArgument.swift
//  
//
//  Created by Kevin Chen on 7/10/19.
//

import Foundation

struct HelpArgument: Argument {
    static let argumentName = "help"
    
    let requiresValue: Bool = false
    
    var value: String?
    
    let description = "Shows a list of options and description"
}
