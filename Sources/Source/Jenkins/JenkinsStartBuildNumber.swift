//
//  JenkinsStartBuildNumber.swift
//  Source
//
//  Created by Kevin Chen on 1/7/19.
//

import Foundation

struct JenkinsStartBuildNumber: Decodable {
    
    enum Source: String {
        case plistConfig
        
        /// Info that is pulled from the last jenkins builds online
        case jenkinsBuildInfoOnline
    }
    
    var value: String
    
    var source: Source?
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        self.value = try container.decode(String.self)
    }
    
    init(value: String, source: Source?) {
        self.value = value
        self.source = source
    }
}
