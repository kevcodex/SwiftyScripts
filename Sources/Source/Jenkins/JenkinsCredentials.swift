//
//  JenkinsCredentials.swift
//  Source
//
//  Created by Kevin Chen on 12/28/18.
//

import Foundation

struct JenkinsCredentials: Codable {
    let email: String
    let apiToken: String
    
    var base64EncodedString: String? {
        let loginString = "\(email):\(apiToken)"
        
        guard let data = loginString.data(using: .utf8) else {
            return nil
        }
        
        return data.base64EncodedString()
    }
}
