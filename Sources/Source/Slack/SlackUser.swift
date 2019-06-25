//
//  SlackUser.swift
//  Source
//
//  Created by Kevin Chen on 2/20/19.
//

import Foundation

struct SlackUser {
    let id: String
    
    /// The string to tag someone on slack
    var taggedString: String {
        return "<@\(id)>"
    }
    
    init?(from user: String) {
        switch user {
            
        case "kchen@phunware.com":
            id = "U66NV87GD"
        case "hpeng@phunware.com":
            id = "U1EFW7R7Y"
        case "hkunwar@phunware.com":
            id = "U1A9NB97S"
        case "nmadera@phunware.com":
            id = "U6RG8AE4C"
        default:
            return nil
        }
    }
}

struct SlackTeam {
    let channel: String
    
    /// The URL path to post to
    let path: String
}
