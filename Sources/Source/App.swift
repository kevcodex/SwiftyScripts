//
//  App.swift
//  Source
//
//  Created by Kevin Chen on 6/26/18.

import Foundation
import ScriptHelpers

// TODO: Find better way to parse without argument type
// as adding a new argument requires mod to arguemnet type which is weird

public struct App {
    
    private var signalObserver: NSObjectProtocol?
    
    public init() {
        
        /// Use notificaiton to get around compile error:
        /// "a C function pointer cannot be formed from a closure that captures context"
        func signalHandler(signal: Int32) {
            NotificationCenter.default.post(name: .SignalRecieved, object: signal)
        }
        
        Signal.monitor(signal: .interrupt, action: signalHandler)
    }
    
    public func start() {
        // MARK: - Setup
        
        // Will be overwritten during build release
        let version = "master"
        
        let arguments = CommandLine.arguments
        
        let terminal = Terminal()
        
        let versionExecutable = VersionExecutable(version: version)
        let helpExecutable = HelpExecutable()
        let startExecutable = StartExecutable()
        let buildExecutable = BuildExecutable()
        
        terminal.run([versionExecutable,
                      helpExecutable,
                      startExecutable,
                      buildExecutable],
                     inputs: arguments)
    }
}
