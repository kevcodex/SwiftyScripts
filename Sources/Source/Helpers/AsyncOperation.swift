//
//  AsyncOperation.swift
//  ScriptHelpers
//
//  Created by Kirby on 10/15/18.
//

import Foundation

open class AsyncOperation: Operation {
    public enum State: String {
        case waiting = "isWaiting"
        case executing = "isExecuting"
        case finished = "isFinished"
    }
    
    public private(set) var state: State = .waiting {
        willSet {
            if newValue != state {
                willChangeValue(forKey: State.executing.rawValue)
                willChangeValue(forKey: State.finished.rawValue)
            }
        }
        didSet {
            if oldValue != state {
                didChangeValue(forKey: State.executing.rawValue)
                didChangeValue(forKey: State.finished.rawValue)
            }
        }
    }
    
    open override var isAsynchronous: Bool {
        return true
    }
    
    open override var isExecuting: Bool {
        return state == .executing
    }
    
    open override var isFinished: Bool {
        return state == .finished
    }
    
    open override func start() {
        state = .executing
        execute()
    }
    
    open func execute() {
        fatalError("You must override this method")
    }
    
    open func finish() {
        state = .finished
    }
}

extension AsyncOperation {
    public func canExecute() -> Bool {
        return !isCancelled && !isFinished
    }
}
