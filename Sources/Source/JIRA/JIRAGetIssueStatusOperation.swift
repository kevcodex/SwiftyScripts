//
//  JIRAGetIssueStatusOperation.swift
//  
//
//  Created by Kevin Chen on 7/16/19.
//

import Foundation
import MiniNe

class JIRAGetIssueStatusOperation: AsyncOperation {
    let credentials: JIRACredentials
    let baseURL: String
    var issue: String
    
    // Outputs
    var result: Swift.Result<JIRAInfo, JIRAError>? {
        didSet {
            self.finish()
        }
    }
    
    init(credentials: JIRACredentials, issue: String, baseURL: String) {
        self.credentials = credentials
        self.issue = issue
        self.baseURL = baseURL
    }
    
    override func execute() {
        let client = MiniNeClient()
        let request = JIRANetworkRequest.getIssueStatusRequest(issue: issue, credentials: credentials, baseURL: baseURL)
        
        client.send(request: request) { (result) in
            
            switch result {
            case .success(let response):
                
                let decoder = JSONDecoder()
                
                do {
                    let jiraInfo = try decoder.decode(JIRAInfo.self, from: response.data)
                    
                    self.result = .success(jiraInfo)
                    
                } catch {
                    self.result = .failure(.decodingError(error))
                }
                
            case .failure(let error):
                self.result = .failure(.networkError(error))
            }
        }
    }
}
