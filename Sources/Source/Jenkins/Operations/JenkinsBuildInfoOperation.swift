//
//  JenkinsBuildInfoOperation.swift
//  Source
//
//  Created by Kevin Chen on 1/4/19.
//

import Foundation
import MiniNe

class JenkinsBuildInfoOperation: AsyncOperation {
    
    let credentials: JenkinsCredentials
    var jobNumber: Int?
    
    init(credentials: JenkinsCredentials, jobNumber: Int?) {
        self.credentials = credentials
        self.jobNumber = jobNumber
    }
    
    // Outputs
    var result: Result<JenkinsBuildInformation, JenkinsError>? {
        didSet {
            self.finish()
        }
    }
    
    override func execute() {
        
        guard let jobNumber = jobNumber else {
            result = Result(error: .missingParameters(["jobNumber"]))
            return
        }
        
        let client = MiniNeClient()
        let request = JenkinsNetworkRequest.buildInformationRequest(credentials: credentials,
                                                                    jobNumber: String(jobNumber))
        
        client.send(request: request) { (result) in
            
            switch result {
            case .success(let response):
                
                let decoder = JSONDecoder()
                
                do {
                    let buildInfo = try decoder.decode(JenkinsBuildInformation.self, from: response.data)
                    
                    self.result = Result(value: buildInfo)
                    
                } catch {
                    self.result = Result(error: .decodingError(error))
                }
                
            case .failure(let error):
                self.result = Result(error: .networkError(error))
            }
        }
    }
}
