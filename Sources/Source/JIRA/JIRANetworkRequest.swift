//
//  JIRANetworkRequest.swift
//  
//
//  Created by Kevin Chen on 7/16/19.
//

import Foundation
import MiniNe

struct JIRANetworkRequest: NetworkRequest {
    var baseURL: URL?
    
    var path: String
    
    var method: HTTPMethod
    
    var parameters: [String : Any]?
    
    var headers: [String : Any]?
    
    var body: NetworkBody?
    
    var acceptableStatusCodes: [Int]
    
    static func generalRequest(credentials: JIRACredentials,
                               baseURL: String,
                               path: String,
                               method: HTTPMethod,
                               parameters: [String: Any]? = nil,
                               headers: [String: Any]? = nil,
                               acceptableStatusCodes: [Int] = Array(200..<300)) -> JIRANetworkRequest {
        
        var headers: [String: Any]? {
            guard let authorization = credentials.base64EncodedString else {
                return headers
            }
            
            var newHeaders: [String: Any] = ["Authorization": "Basic \(authorization)"]
            
            if let headers = headers {
                newHeaders.merge(headers, uniquingKeysWith: { _, last in last })
            }
            
            return newHeaders
        }
        
        return self.init(baseURL: URL(string: baseURL),
                         path: path,
                         method: method,
                         parameters: parameters,
                         headers: headers,
                         acceptableStatusCodes: acceptableStatusCodes)
    }
    
    
    static func getIssueStatusRequest(issue: String, credentials: JIRACredentials, baseURL: String) -> JIRANetworkRequest {
        
        let parameters: [String: Any] = ["fields": "status"]
        
        return generalRequest(
            credentials: credentials,
            baseURL: baseURL,
            path: "/rest/api/2/issue/\(issue)",
            method: .get,
            parameters: parameters)
    }
}
