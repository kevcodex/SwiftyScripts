//
//  JenkinsCrumbOperation.swift
//  Source
//
//  Created by Kevin Chen on 12/26/18.
//

import Foundation
import MiniNe

class JenkinsCrumbOperation: AsyncOperation {
    
    let baseURL: URL
    let credentials: JenkinsCredentials
    
    init(baseURL: URL, credentials: JenkinsCredentials) {
        self.baseURL = baseURL
        self.credentials = credentials
    }
    
    // Outputs
    var result: Result<JenkinsCrumbResponse, JenkinsError>? {
        didSet {
            self.finish()
        }
    }
    
    override func execute() {
        let client = MiniNeClient()
        let request = JenkinsNetworkRequest.crumbIssuerRequest(baseURL: baseURL, credentials: credentials)
        
        client.send(request: request) { (result) in
            
            switch result {
            case .success(let response):
                
                let decoder = JSONDecoder()
                
                do {
                    let crumbResponse = try decoder.decode(JenkinsCrumbResponse.self, from: response.data)
                    
                    self.result = Result(value: crumbResponse)
                    
                } catch {
                    self.result = Result(error: .decodingError(error))
                }
                
            case .failure(let error):
                self.result = Result(error: .networkError(error))
            }
        }
    }
}
