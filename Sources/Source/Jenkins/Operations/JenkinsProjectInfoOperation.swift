//
//  JenkinsProjectInfoOperation.swift
//  Source
//
//  Created by Kevin Chen on 1/2/19.
//

import Foundation
import MiniNe

class JenkinsProjectInfoOperation: AsyncOperation {
    
    let baseURL: URL
    let credentials: JenkinsCredentials
    
    init(baseURL: URL, credentials: JenkinsCredentials) {
        self.baseURL = baseURL
        self.credentials = credentials
    }
    
    // Outputs
    var result: Result<JenkinsJobInformation, JenkinsError>? {
        didSet {
            self.finish()
        }
    }
    
    override func execute() {
        let client = MiniNeClient()
        let request = JenkinsNetworkRequest.projectInformationRequest(baseURL: baseURL, credentials: credentials)
        
        client.send(request: request) { (result) in
            
            switch result {
            case .success(let response):
                
                let decoder = JSONDecoder()
                
                do {
                    let jobInfo = try decoder.decode(JenkinsJobInformation.self, from: response.data)
                    
                    self.result = Result(value: jobInfo)
                    
                } catch {
                    self.result = Result(error: .decodingError(error))
                }
                
            case .failure(let error):
                self.result = Result(error: .networkError(error))
            }
        }
    }
}
