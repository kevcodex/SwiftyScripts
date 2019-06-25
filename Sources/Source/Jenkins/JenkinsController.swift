//
//  JenkinsController.swift
//  Source
//
//  Created by Kevin Chen on 12/26/18.
//

import Foundation

enum JenkinsError: Error {
    case invalidURL
    case invalidCrumb
    case networkError(Error)
    case decodingError(Error)
    case missingParameters([String])
    case other(message: String)
    case unknown
}

final class JenkinsController {
    
    private let credentials: JenkinsCredentials
    private let operationQueue = OperationQueue()
    
    init(credentials: JenkinsCredentials) {
        self.credentials = credentials
        operationQueue.maxConcurrentOperationCount = 5
    }
    
    /// Fetches the crumb synchronously
    func fetchCrumb(completion: @escaping (Result<JenkinsCrumbResponse, JenkinsError>) -> Void) {
        
        let fullCrumbOperations = crumbOperations { (result) in
            completion(result)
        }
        
        operationQueue.addOperations(fullCrumbOperations,
                                     waitUntilFinished: false)
        
        operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    /// Gets crumb and then posts build synchronously
    func startDeploymentBuild(with parameters: [String: Any], completion: @escaping (Result<Void, JenkinsError>) -> Void) {
        
        let buildOperation = JenkinsBuildOperation(credentials: credentials, crumb: nil, parameters: parameters)
        
        let fullCrumbOperations = crumbOperations { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let crumbResponse):
                buildOperation.crumb = crumbResponse.crumb
            case .failure(let error):
                completion(Result(error: error))
                strongSelf.operationQueue.cancelAllOperations()
            }
        }
        
        let completionBlock = BlockOperation { [weak buildOperation] in
            guard let result = buildOperation?.result else {
                completion(Result(error: .unknown))
                return
            }
            
            completion(result)
        }
        
        if let lastOperation = fullCrumbOperations.last {
            buildOperation.addDependency(lastOperation)
        }
        
        completionBlock.addDependency(buildOperation)
        
        operationQueue.addOperations(fullCrumbOperations,
                                     waitUntilFinished: false)
        operationQueue.addOperations([buildOperation,
                                      completionBlock],
                                     waitUntilFinished: false)
        
        operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    func addDescriptionToLastBuild(description: String, completion: @escaping (Result<Void, JenkinsError>) -> Void) {
            
        let projectInfoOperation = JenkinsProjectInfoOperation(credentials: credentials)
        let descriptionModifierOperation = JenkinsDescriptionModifierOperation(credentials: credentials, jobDescription: description, crumb: nil, jobNumber: nil)
        
        let fullCrumbOperations = crumbOperations { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let crumbResponse):
                descriptionModifierOperation.crumb = crumbResponse.crumb
            case .failure(let error):
                completion(Result(error: error))
                strongSelf.operationQueue.cancelAllOperations()
            }
        }
        
        let projectInfoCompletionBlock = BlockOperation { [weak self, weak projectInfoOperation] in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let result = projectInfoOperation?.result else {
                completion(Result(error: .unknown))
                return
            }
            
            switch result {
            case .success(let info):
                descriptionModifierOperation.jobNumber = info.builds.first?.number
            case .failure(let error):
                completion(Result(error: error))
                strongSelf.operationQueue.cancelAllOperations()
            }
        }
        
        let descriptionModifierCompletion = BlockOperation { [weak descriptionModifierOperation] in
            
            guard let result = descriptionModifierOperation?.result else {
                completion(Result(error: .unknown))
                return
            }
            
            completion(result)
        }
        
        projectInfoCompletionBlock.addDependency(projectInfoOperation)
        descriptionModifierOperation.addDependency(projectInfoCompletionBlock)
        
        if let lastOperation = fullCrumbOperations.last {
            descriptionModifierOperation.addDependency(lastOperation)
        }
        
        descriptionModifierCompletion.addDependency(descriptionModifierOperation)
        
        operationQueue.addOperations(fullCrumbOperations,
                                     waitUntilFinished: false)
        operationQueue.addOperations([projectInfoOperation,
                                      projectInfoCompletionBlock,
                                      descriptionModifierOperation,
                                      descriptionModifierCompletion],
                                     waitUntilFinished: false)
        
        operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    /// Fetch the latest build numbers for targets
    func fetchLatestBuildNumbers(targets: [String], completion: @escaping (Result<[String: Int], JenkinsError>) -> Void) {
        
        let maxBuildsCount = targets.count * 3
        
        let projectInfoOperation = JenkinsProjectInfoOperation(credentials: credentials)
        
        var buildInfoOperations = [JenkinsBuildInfoOperation]()
        
        for _ in 1...maxBuildsCount {
            let buildInfoOperation = JenkinsBuildInfoOperation(credentials: credentials, jobNumber: nil)
            buildInfoOperations.append(buildInfoOperation)
        }
        
        let projectInfoCompletionBlock = BlockOperation { [weak self, weak projectInfoOperation] in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let result = projectInfoOperation?.result else {
                completion(Result(error: .unknown))
                return
            }
            
            switch result {
            case .success(let info):
                for index in buildInfoOperations.indices {
                    
                    if info.builds.indices.contains(index) {
                        buildInfoOperations[index].jobNumber = info.builds[index].number
                    }
                }
                
                // Remove operations that don't have a job number as they will fail
                buildInfoOperations = buildInfoOperations.filter { $0.jobNumber != nil }
                
            case .failure(let error):
                completion(Result(error: error))
                strongSelf.operationQueue.cancelAllOperations()
            }
        }
        
        let completionBlock = BlockOperation {
            
            var dict = [String: Int]()
            
            for buildOperation in buildInfoOperations {
                
                guard let result = buildOperation.result else {
                    continue
                }
                
                switch result {
                case .success(let buildInfo):
                    
                    if let extractedTargetString = buildInfo.extractValue(for: .scheme,
                                                                 expectedType: String.self),
                        let extractedBuildNumberString = buildInfo.extractValue(for: .startBuildNumber,
                                                                      expectedType: String.self),
                        let extractedBuildNumberIntegar = Int(extractedBuildNumberString) {

                        
                        // Only store values of targets that are defined in list of targets
                        guard targets.contains(extractedTargetString) else {
                            continue
                        }
                        // Check if target is already in dict
                        // if it is then compare values
                        // Keep the largest value
                        if let storedBuildNumber = dict[extractedTargetString] {
                            
                            if storedBuildNumber < extractedBuildNumberIntegar {
                                dict[extractedTargetString] = extractedBuildNumberIntegar
                            }
                        } else {
                            dict[extractedTargetString] = extractedBuildNumberIntegar
                        }
                    } else {
                        
                        completion(Result(error: .other(message: "Error getting value from build info: \(buildInfo.description)")))
                        return
                    }
                    
                case .failure(let error):
                    completion(Result(error: error))
                    return
                }
            }
            
            guard !dict.isEmpty else {
                completion(Result(error: .other(message: "No items in mapping")))
                return
            }
            
            completion(Result(value: dict))
        }
        
        
        projectInfoCompletionBlock.addDependency(projectInfoOperation)
        
        for buildInfo in buildInfoOperations {
            buildInfo.addDependency(projectInfoCompletionBlock)
            completionBlock.addDependency(buildInfo)
        }
        
        operationQueue.addOperations([projectInfoOperation,
                                      projectInfoCompletionBlock,
                                      completionBlock],
                                     waitUntilFinished: false)
        operationQueue.addOperations(buildInfoOperations,
                                     waitUntilFinished: false)

        
        operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    private func crumbOperations(completion: @escaping (Result<JenkinsCrumbResponse, JenkinsError>) -> Void) -> [Operation] {
        let jenkinsCrumbOperation = JenkinsCrumbOperation(credentials: credentials)
        
        let completionBlock = BlockOperation { [weak jenkinsCrumbOperation] in
            guard let result = jenkinsCrumbOperation?.result else {
                completion(Result(error: .unknown))
                return
            }
            
            completion(result)
        }
        
        completionBlock.addDependency(jenkinsCrumbOperation)
        
        return [jenkinsCrumbOperation, completionBlock]
    }
}
