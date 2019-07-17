//
//  SlackController.swift
//  MiniNe
//
//  Created by Kevin Chen on 2/20/19.
//

import Foundation

final class SlackController {

    private let operationQueue = OperationQueue()
    
    var slackUser: SlackUser?
    
    var team: SlackTeam?
    
    init() {
        operationQueue.maxConcurrentOperationCount = 5
    }
    
    func setup(slackUser: String, channel: String, path: String) {
        self.slackUser = SlackUser(from: slackUser)
        self.team = SlackTeam(channel: channel, path: path)
    }
    
    func postStartMessage(completion: @escaping (Result<Void, SlackError>) -> Void) {
        let message = SlackMessage.startedMessage(slackID: slackUser?.taggedString ?? "Anonymous")
        
        postMessage(message, completion: completion)
    }
    
    func postPRMessage(bitbucketParameters: [String: Any], completion: @escaping (Result<Void, SlackError>) -> Void) {
        
        let urlString = BitbucketNetworkRequest.createPullRequestOnWeb(parameters: bitbucketParameters).buildURLRequest()?.url?.absoluteString
        
        let message = SlackMessage.prMessage(slackID: slackUser?.taggedString ?? "Anonymous", urlString: urlString)
        
        postMessage(message, completion: completion)
    }
    
    func postFinishedTeamMergeMessage(completion: @escaping (Result<Void, SlackError>) -> Void) {
        let message = SlackMessage.finishedTeamMergeMessage(slackID: slackUser?.taggedString ?? "Anonymous")
        
        postMessage(message, completion: completion)
    }
    
    func postStartJenkinsMessage(completion: @escaping (Result<Void, SlackError>) -> Void) {
        let message = SlackMessage.startedJenkinsMessage(slackID: slackUser?.taggedString ?? "Anonymous")
        
        postMessage(message, completion: completion)
    }
    
    func postFinishedJenkinsMessage(completion: @escaping (Result<Void, SlackError>) -> Void) {
        let message = SlackMessage.finishedJenkinsMessage(slackID: slackUser?.taggedString ?? "Anonymous")
        
        postMessage(message, completion: completion)
    }
    
    func postErrorMessage(errorMessage: String, completion: @escaping (Result<Void, SlackError>) -> Void) {
        let message = SlackMessage.errorMessage(slackID: slackUser?.taggedString ?? "Anonymous",
                                                errorMessage: errorMessage)
        
        postMessage(message, completion: completion)
    }
    
    func postMessage(_ message: SlackMessage, completion: @escaping (Result<Void, SlackError>) -> Void) {
        
        guard let team = team else {
            completion(Result(error: .other(message: "Missing Slack Team Info")))
            return
        }
        
        var message = message
        message.channel = team.channel
        
        let request: SlackNetworkRequest = .postMessage(path: team.path, slackMessage: message)

        let messageOperation = SlackMessageOperation(request: request, message: message)
        
        let completionBlock = BlockOperation { [weak messageOperation] in
            guard let result = messageOperation?.result else {
                return
            }
            
            completion(result)
        }
        
        completionBlock.addDependency(messageOperation)
        
        operationQueue.addOperations([messageOperation,
                                      completionBlock],
                                     waitUntilFinished: false)
        
        operationQueue.waitUntilAllOperationsAreFinished()
    }
}
