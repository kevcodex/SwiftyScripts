//
//  JenkinsJobInformation.swift
//  Source
//
//  Created by Kevin Chen on 1/2/19.
//

import Foundation

struct JenkinsJobInformation: Codable {
    let builds: [Build]
}

extension JenkinsJobInformation {
    struct Build: Codable {
        let number: Int
        let url: String
    }
}
