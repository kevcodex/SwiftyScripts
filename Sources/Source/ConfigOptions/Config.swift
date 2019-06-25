//
//  Config.swift
//  Source
//
//  Created by Kevin Chen on 12/28/18.
//

import Foundation

// Unneeded? Since I individually parse out each item
struct Config: Decodable {
    let targets: [String]
    let branches: [Branch]
    
    let jenkins: JenkinsConfig?
    
    private enum CodingKeys: String, CodingKey {
        case jenkins = "Jenkins"
        case targets = "TargetsToRun"
        case branches = "BranchesToRun"
    }
}
