//
//  SlackMessageOperation.swift
//  Source
//
//  Created by Kevin Chen on 2/20/19.
//

import Foundation
import MiniNe

class SlackMessageOperation: AsyncOperation {
    
    let request: SlackNetworkRequest
    let message: SlackMessage
    
    // Outputs
    var result: Result<Void, SlackError>? {
        didSet {
            self.finish()
        }
    }
    
    init(request: SlackNetworkRequest, message: SlackMessage) {
        self.request = request
        self.message = message
    }
    
    override func execute() {
        let client = MiniNeClient()
        
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
