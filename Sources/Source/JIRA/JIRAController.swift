//
//  JIRAController.swift
//  
//
//  Created by Kevin Chen on 7/16/19.
//

import Foundation

enum JIRAError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case unknown
}

struct JIRAController {
    private let credentials: JIRACredentials
    private let operationQueue = OperationQueue()
    
    init(credentials: JIRACredentials) {
        self.credentials = credentials
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    func checkStatus(for branches: inout [BranchContext],
                     baseURL: String,
                     closedStatus: String) {
        
        var closedIndices = [Int]()
        
        for (index, branch) in branches.enumerated() {
            if let jiraIssue = branch.jiraIssue {
                let operation = JIRAGetIssueStatusOperation(credentials: credentials, issue: jiraIssue, baseURL: baseURL)
                
                let completionBlock = BlockOperation { [weak operation] in
                    guard let result = operation?.result else {
                        // TODO: - Handle errors, maybe keep track of error indices and display for client to see
                        print("Something went wrong")
                        return
                    }
                    
                    switch result {
                    case .success(let jiraInfo):
                        if let status = jiraInfo.fields?.status?.name,
                            status == closedStatus {
                            closedIndices.append(index)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
                
                completionBlock.addDependency(operation)
                operationQueue.addOperations([operation,
                                              completionBlock],
                                             waitUntilFinished: false)
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        for index in closedIndices {
            branches[index].ticketIsClosed = true
        }
    }
}
