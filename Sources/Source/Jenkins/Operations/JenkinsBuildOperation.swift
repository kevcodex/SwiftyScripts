//
//  JenkinsBuildOperation.swift
//  Source
//
//  Created by Kevin Chen on 12/26/18.
//

import Foundation
import MiniNe

class JenkinsBuildOperation: AsyncOperation {
    
    let baseURL: URL
    let parameters: [String: Any]
    let credentials: JenkinsCredentials
    var crumb: String?
    
    // Outputs
    var result: Result<Void, JenkinsError>? {
        didSet {
            self.finish()
        }
    }
    
    init(baseURL: URL, credentials: JenkinsCredentials, crumb: String?, parameters: [String: Any]) {
        self.baseURL = baseURL
        self.credentials = credentials
        self.crumb = crumb
        self.parameters = parameters
    }
    
    override func execute() {
        
        guard let crumb = crumb else {
            result = Result(error: .invalidCrumb)
            return
        }
        
        let client = MiniNeClient()
        let request = JenkinsNetworkRequest.buildRequest(baseURL: baseURL, credentials: credentials, crumb: crumb, parameters: parameters)
        
        client.send(request: request) { (result) in
            
            switch result {
            case .success:
                
                self.result = .success
                
            case .failure(let error):
                self.result = Result(error: .networkError(error))
            }
        }
    }
}
