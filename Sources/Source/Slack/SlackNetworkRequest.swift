//
//  SlackNetworkRequest.swift
//  MiniNe
//
//  Created by Kevin Chen on 2/20/19.
//

import MiniNe
import Foundation

struct SlackNetworkRequest: NetworkRequest {
    
    var baseURL: URL? {
        return URL(string: "https://hooks.slack.com")
    }
    
    private(set) var path: String
    
    private(set) var method: HTTPMethod
    
    var parameters: [String: Any]? {
        return nil
    }
    
    var headers: [String: Any]? {
        return nil
    }
    
    private(set) var body: NetworkBody?

    static func foxInternalRequest(path: String, slackMessage: SlackMessage) -> SlackNetworkRequest {
                
        let body: NetworkBody? = {
            let encoder = JSONEncoder()
            
            guard let data = try? encoder.encode(slackMessage) else {
                return nil
            }
            
            return NetworkBody(data: data, encoding: .json)
        }()
        
        return self.init(path: path,
                         method: .post,
                         body: body)
    }
}
