//
//  JIRACredentials.swift
//  
//
//  Created by Kevin Chen on 7/12/19.
//

import Foundation

struct JIRACredentials: Codable {
    let email: String
    let password: String
    
    var base64EncodedString: String? {
        let loginString = "\(email):\(password)"
        
        guard let data = loginString.data(using: .utf8) else {
            return nil
        }
        
        return data.base64EncodedString()
    }
}
