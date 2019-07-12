//
//  BranchContext.swift
//  
//
//  Created by Kevin Chen on 7/12/19.
//

import Foundation

struct BranchContext {
    let branchName: String
    
    var ticketIsClosed: Bool = false
    
    var jiraIssue: String? {
        let range = NSRange(location: 0, length: branchName.count)
        
        guard let regex = try? NSRegularExpression(pattern: "[A-Z0-9]{1,10}-?[A-Z0-9]+-\\d+"),
            let match = regex.firstMatch(in: branchName, options: [], range: range),
            let stringRange = Range(match.range, in: branchName) else {
                return nil
        }
        
        return String(branchName[stringRange])
    }
}
