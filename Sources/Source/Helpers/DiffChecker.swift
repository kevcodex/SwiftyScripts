//
//  DiffChecker.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 3/27/18.
//

import Foundation
import ScriptHelpers

/// Continiously check the difference between two branches
class DiffChecker {
    
    typealias RestartingBlock = (_ message: String, _ timeTillCheck: TimeInterval) -> Void
    typealias FinishedBlock = (_ success: Bool, _ error: RunError?) -> Void
    
    private var timer: Timer?
    
    private let branch1: String?
    private let branch2: String
    private let finished: FinishedBlock
    private let restarting: RestartingBlock
    
    private let timeToCheck: TimeInterval = 10.0
    
    @discardableResult
    init(branch1: String?, branch2: String, restarting: @escaping RestartingBlock, finished: @escaping FinishedBlock) {
        self.branch1 = branch1
        self.branch2 = branch2
        self.restarting = restarting
        self.finished = finished
        
        fetch { (didSucceed, error)  in
            if didSucceed {
                self.checkDifference(branch1: branch1, branch2: branch2, restarting: restarting, finished: finished)
            } else {
                finished(false, error)
            }
        }
    }
    
    private func checkDifference(branch1: String?,
                                 branch2: String,
                                 restarting: @escaping RestartingBlock,
                                 finished: @escaping FinishedBlock) {
        let diffCommand = GitCommand(arguments: [.diff(branch1: branch1, branch2: branch2, options: [.nameOnly])])
        diffCommand.run { (result) in
            switch result {
            case .success(let message):
                // No diff then team merge and release are same
                // Continue onto merging into other branches
                if message.isEmpty {
                    finished(true, nil)
                } else {
                    restarting(message, self.timeToCheck)
                    self.startTimer()
                }
                
            case .failure(let error):
                finished(false, error)
            }
        }
    }
    
    private func startTimer() {
        
        invalidateTimer()
        
        Console.writeSpacer()
        
        let timeInterval = timeToCheck
        
        timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                     target: self,
                                     selector: #selector(check),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetch(_ completion: @escaping FinishedBlock) {
        // Need to fetch to check diff
        
        let fetchCommand = GitCommand(arguments: [.fetchAll])
        fetchCommand.run(completion: { (result) in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        })
    }
    
    @objc private func check() {
        fetch { (didSucceed, error)  in
            if didSucceed {
                self.checkDifference(branch1: self.branch1, branch2: self.branch2, restarting: self.restarting, finished: self.finished)
            } else {
                self.finished(false, error)
            }
        }
    }
}
