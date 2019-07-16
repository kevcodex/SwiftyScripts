//
//  JIRAInfo.swift
//  
//
//  Created by Kevin Chen on 7/16/19.
//

import Foundation

struct JIRAInfo: Decodable {
    let fields: Fields?
    
    struct Fields: Decodable {
        let status: Status?
        
        struct Status: Decodable {
            let name: String?
        }
    }
}
