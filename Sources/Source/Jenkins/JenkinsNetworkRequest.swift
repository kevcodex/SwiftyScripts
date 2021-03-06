//
//  JenkinsNetworkRequest.swift
//  Source
//
//  Created by Kevin Chen on 12/26/18.
//

import Foundation
import MiniNe

struct JenkinsNetworkRequest: NetworkRequest {
    
    var baseURL: URL?
    
    private(set) var path: String
    
    private(set) var method: HTTPMethod
    
    private(set) var parameters: [String: Any]?
    
    private(set) var headers: [String: Any]?
    
    private(set) var acceptableStatusCodes: [Int]
    
    var body: NetworkBody? {
        return nil
    }
    
    private init(baseURL: URL,
                 path: String,
                 method: HTTPMethod,
                 parameters: [String: Any]?,
                 headers: [String: Any]?,
                 acceptableStatusCodes: [Int] = Array(200..<300)) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.acceptableStatusCodes = acceptableStatusCodes
    }
    
    /// General request for any jenkins url path.
    /// Will convert credentials to basic auth.
    static func generalRequest(baseURL: URL,
                               credentials: JenkinsCredentials,
                               path: String,
                               method: HTTPMethod,
                               parameters: [String: Any]? = nil,
                               headers: [String: Any]? = nil,
                               acceptableStatusCodes: [Int] = Array(200..<300)) -> JenkinsNetworkRequest {
        
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
        
        return self.init(baseURL: baseURL,
                         path: path,
                         method: method,
                         parameters: parameters,
                         headers: headers,
                         acceptableStatusCodes: acceptableStatusCodes)
    }
    
    static func crumbIssuerRequest(baseURL: URL, credentials: JenkinsCredentials) -> JenkinsNetworkRequest {
        
        return generalRequest(baseURL: baseURL,
                              credentials: credentials,
                              path: "/crumbIssuer/api/json",
                              method: .get)
    }
    
    static func buildRequest(baseURL: URL, credentials: JenkinsCredentials, crumb: String, parameters: [String: Any]) -> JenkinsNetworkRequest {
        
        let headers: [String: Any] = ["Jenkins-Crumb": crumb]
        
        return generalRequest(baseURL: baseURL,
                              credentials: credentials,
                              path: "/job/dcg-tvos-framework/buildWithParameters",
                              method: .post,
                              parameters: parameters,
                              headers: headers)
    }
    
    static func descriptionModifierRequest(baseURL: URL, credentials: JenkinsCredentials, crumb: String, jobNumber: String, parameters: [String: Any]) -> JenkinsNetworkRequest {
        
        let headers: [String: Any] = ["Jenkins-Crumb": crumb]
        
        var codes = Array(200..<300)
        codes.append(403)
        
        let path = "/job/dcg-tvos-framework/\(jobNumber)/submitDescription"
        
        return generalRequest(baseURL: baseURL,
                              credentials: credentials,
                              path: path,
                              method: .post,
                              parameters: parameters,
                              headers: headers,
                              acceptableStatusCodes: codes)
    }
    
    /// Fetches information related to the job in json format
    static func projectInformationRequest(baseURL: URL, credentials: JenkinsCredentials) -> JenkinsNetworkRequest {
        
        return generalRequest(baseURL: baseURL,
                              credentials: credentials,
                              path: "/job/dcg-tvos-framework/api/json",
                              method: .get)
    }
    
    /// Fetches information related to the build in json format
    static func buildInformationRequest(baseURL: URL, credentials: JenkinsCredentials, jobNumber: String) -> JenkinsNetworkRequest {
        
        return generalRequest(baseURL: baseURL,
                              credentials: credentials,
                              path: "/job/dcg-tvos-framework/\(jobNumber)/api/json",
            method: HTTPMethod.get)
    }
}
