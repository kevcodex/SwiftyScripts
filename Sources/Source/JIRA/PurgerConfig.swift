//
//  PurgerConfig.swift
//  
//
//  Created by Kevin Chen on 7/15/19.
//

import Foundation

struct PurgerConfig: Codable {
    let branchFolder: String
    let repoURL: String
    let jira: Jira
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        
        let purgerContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                            forKey: .purger)
        
        branchFolder = try purgerContainer.decode(String.self, forKey: .branchFolder)
        repoURL = try purgerContainer.decode(String.self, forKey: .repoURL)
        jira = try purgerContainer.decode(Jira.self, forKey: .jira)
    }
    
    private enum RootKeys: String, CodingKey {
        case purger = "Purger"
    }
    
    enum CodingKeys: String, CodingKey {
        case branchFolder
        case repoURL
        case jira = "Jira"
    }
    
    struct Jira: Codable {
        let url: String
        let email: String
        let password: String
    }
}
