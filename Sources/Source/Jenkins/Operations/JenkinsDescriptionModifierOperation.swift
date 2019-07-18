//
//  JenkinsDescriptionModifierOperation.swift
//  Source
//
//  Created by Kevin Chen on 1/2/19.
//

import Foundation
import MiniNe

class JenkinsDescriptionModifierOperation: AsyncOperation {
    
    let baseURL: URL
    let credentials: JenkinsCredentials
    let jobDescription: String
    var crumb: String?
    var jobNumber: Int?
    
    init(baseURL: URL, credentials: JenkinsCredentials, jobDescription: String, crumb: String?, jobNumber: Int?) {
        self.baseURL = baseURL
        self.credentials = credentials
        self.jobDescription = jobDescription
        self.crumb = crumb
        self.jobNumber = jobNumber
    }
    
    // Outputs
    var result: Result<Void, JenkinsError>? {
        didSet {
            self.finish()
        }
    }
    
    override func execute() {
    
        guard let crumb = crumb else {
            result = Result(error: .invalidCrumb)
            return
        }
        
        guard let jobNumber = jobNumber else {
            result = Result(error: .missingParameters(["jobNumber"]))
            return
        }
        
        let parameters = ["description": jobDescription]
        
        let client = MiniNeClient()
        let request = JenkinsNetworkRequest.descriptionModifierRequest(baseURL: baseURL,
                                                                       credentials: credentials,
                                                                       crumb: crumb,
                                                                       jobNumber: String(jobNumber),
                                                                       parameters: parameters)
        
        client.send(request: request) { [weak self] (result) in
            
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let response):
                
                // Description request makes a redirect which will fail with 403 since headers are not passed along
                // Therefore, make another request to that same url requesting json and verify if description matches input
                // Maybe instead consider conforming to urlsession delegate and modify url redirect?
                guard response.statusCode != 403 else {
                    strongSelf.verifyDescription(from: response.requestURL)
                    return
                }
                
                strongSelf.result = .success
                
            case .failure(let error):
                strongSelf.result = Result(error: .networkError(error))
            }
        }
    }
    
    /// Get build info and check if inputted description matches build info description
    private func verifyDescription(from url: URL?) {
        
        guard let url = url else {
            result = Result(error: .other(message: "Missing request url"))
            return
        }
        
        let client = MiniNeClient()
        let request = JenkinsNetworkRequest.generalRequest(baseURL: baseURL,
                                                           credentials: credentials,
                                                           path: url.path + "/api/json",
                                                           method: .get)
        
        client.send(request: request) { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let response):
                
                let decoder = JSONDecoder()
                
                do {
                    let buildInfo = try decoder.decode(JenkinsBuildInformation.self, from: response.data)
                    
                    guard buildInfo.description == strongSelf.jobDescription else {
                        strongSelf.result = Result(error: .other(message: "Mismatched input and retrieved description"))
                        return
                    }
                    
                    strongSelf.result = .success
                    
                } catch {
                    strongSelf.result = Result(error: .decodingError(error))
                }
            case .failure(let error):
                strongSelf.result = Result(error: .networkError(error))
            }
        }
    }
}
