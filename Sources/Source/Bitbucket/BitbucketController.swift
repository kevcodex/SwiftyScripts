//
//  BitbucketController.swift
//  Source
//
//  Created by Kevin Chen on 1/16/19.
//

import Foundation
import Cocoa

enum BitbucketError: Error {
    case invalidURL
    case failedOpeningURL
    case unknown
}

final class BitbucketController {
    
    let baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    static func parameters(for sourceBranch: String, targetBranch: String) -> [String: Any] {
        let parameters: [String: Any] = ["create": "",
                                         "sourceBranch": sourceBranch,
                                         "targetBranch": targetBranch]
        return parameters
    }

    func redirectToBitbucket(sourceBranch: String, targetBranch: String) throws {

        let parameters = BitbucketController.parameters(for: sourceBranch, targetBranch: targetBranch)
        
        let request = BitbucketNetworkRequest.createPullRequestOnWeb(baseURL: baseURL, parameters: parameters)
        
        guard let urlRequest = request.buildURLRequest(),
            let url = urlRequest.url else {
                throw BitbucketError.invalidURL
        }
        
        if NSWorkspace.shared.open(url) {
            
        } else {
            throw BitbucketError.failedOpeningURL
        }
    }
}
