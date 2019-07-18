//
//  BitbucketNetworkRequest.swift
//  Source
//
//  Created by Kevin Chen on 1/16/19.
//

import Foundation
import MiniNe

struct BitbucketNetworkRequest: NetworkRequest {
    var baseURL: URL?
    
    private(set) var path: String
    
    private(set) var method: HTTPMethod
    
    private(set) var parameters: [String: Any]?
    
    private(set) var headers: [String: Any]?
    
    private(set) var body: NetworkBody?
    
    private(set) var acceptableStatusCodes: [Int]
    
    private init(baseURL: URL,
                 path: String,
                 method: HTTPMethod,
                 parameters: [String: Any]?,
                 headers: [String: Any]?,
                 body: NetworkBody? = nil,
                 acceptableStatusCodes: [Int] = Array(200..<300)) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
        self.acceptableStatusCodes = acceptableStatusCodes
    }
    
    /// This is the network request for the web based PR creation
    static func createPullRequestOnWeb(baseURL: URL, parameters: [String: Any]) -> BitbucketNetworkRequest {
        
        return self.init(baseURL: baseURL,
                         path: "/projects/dcgpe/repos/dcg-tvos-framework/pull-requests",
                         method: .get,
                         parameters: parameters,
                         headers: nil)
    }
}
