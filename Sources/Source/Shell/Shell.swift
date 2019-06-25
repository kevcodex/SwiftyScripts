//
//  Shell.swift
//  Source
//
//  Created by Kevin Chen on 1/10/19.
//

import Foundation

class Shell {
    var environment = ProcessInfo.processInfo.environment
    
    var currentDirectory: String {
        return FileManager.default.currentDirectoryPath
    }
    
    private var signalObserver: NSObjectProtocol?
    
    private var currentRunningProcess: Process?
    
    init() {
        //            NotificationCenter.default.addObserver(self, selector: #selector(test), name: Process.didTerminateNotification, object: nil)
        
        addSignalNotification()
    }
    
    func addSignalNotification() {
        let signalReceived: (Notification) -> Void = { notification in
            
            NotificationCenter.default.removeObserver(self.signalObserver!)
            
            guard let signal = notification.object as? Int32 else {
                return
            }
            
            guard signal != 0 else {
                return
            }
            
            self.currentRunningProcess?.interrupt()
            
            // Future: Look into moving exit to the app level
            // Need to create a wrapper that queue the notifcations in the order I want
            // as notifcation cetner will fire FIFO
            // The issues is if i add observer at app level that will exit, that observer will get called first
            // Therefore, I need to make a container where when I add an observer it will place it in a certain priority level and then modify the notifcation center so the observer is added to correct level
            exit(signal)
        }

        signalObserver = NotificationCenter.default.addObserver(forName: .SignalRecieved,
                                                                object: nil,
                                                                queue: OperationQueue.main,
                                                                using: signalReceived)
    }
    
    /// Runs a command and will continiously output the
    func runAndPrint(_ executable: String, _ args: [String]) throws {
        currentRunningProcess = try createProcess(executable, args: args)
        
        try currentRunningProcess?.tryLaunching()
        try currentRunningProcess?.tryFinishing()
    }
    
    func runAndPrintBash(_ bashCommand: String) throws {
        try runAndPrint("/bin/bash", ["-c", bashCommand])
    }
    
    /// Runs a command and outputs the result after running the command
    @discardableResult
    func run(_ executable: String, _ args: [String]) throws -> String {
        currentRunningProcess = try createProcess(executable, args: args)
        
        let outpipe = Pipe()
        currentRunningProcess?.standardOutput = outpipe
        
        let errorPipe = Pipe()
        currentRunningProcess?.standardError = errorPipe
        
        try currentRunningProcess?.tryLaunching()
        
        do {
            try currentRunningProcess?.tryFinishing()
        } catch ShellError.returnedErrorCode(let command, let errorCode) {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let output = String(data: data, encoding: .utf8) else {
                throw ShellError.runError(message: "Could not convert error output data to string!")
            }
            
            throw ShellError.runError(message: "Error running: \(command)), code: \(errorCode), messsage: \(output)")
        } catch {
            throw error
        }
        
        let data = outpipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let output = String(data: data, encoding: .utf8) else {
            throw ShellError.runError(message: "Could not convert output data to string!")
        }
        
        return cleanUpNewLineIfNeeded(output)
    }
    
    func changeCurrentDirectory(to path: String) throws {
        if !FileManager.default.changeCurrentDirectoryPath(path) {
            throw ShellError.invalidPath(path)
        }
    }
    
    private func createProcess(_ executable: String, args: [String]) throws -> Process {
        let process = Process()
        process.arguments = args
        process.launchPath = try launchPath(executable)
        process.environment = environment
        process.currentDirectoryPath = currentDirectory
        
        process.standardOutput = FileHandle.standardOutput
        process.standardInput = FileHandle.standardInput
        process.standardError = FileHandle.standardError
        
        return process
    }
    
    private func launchPath(_ executable: String) throws -> String {
        guard !executable.contains("/") else {
            return executable
        }
        
        let output = try run("/usr/bin/which", [executable])
        return output
        
    }
    
    private func cleanUpNewLineIfNeeded(_ text: String) -> String {
        let afterfirstnewline = text.firstIndex(of: "\n").map(text.index(after:))
        
        return (afterfirstnewline == nil || afterfirstnewline == text.endIndex)
            ? text.trimmingCharacters(in: .whitespacesAndNewlines)
            : text
    }
    
    //        @objc func test(_ notification: Notification) {
    //            let process = notification.object as? Process
    //            print(process?.terminationStatus)
    //
    //            if let terminationStatus = process?.terminationStatus,
    //                terminationStatus != 0 {
    //
    //                print("terminating")
    //            }
    //
    //            print("something")
    //        }
}

enum ShellError: Error, Equatable {
    case invalidExecutable(path: String)
    case missingExecutable
    
    case returnedErrorCode(command: String, errorcode: Int)
    case runError(message: String)
    
    case invalidPath(String)
}

extension Process {
    
    /// Tries to launch process if possible
    func tryLaunching() throws {
        
        guard let launchPath = self.launchPath else {
            throw ShellError.missingExecutable
        }
        
        guard FileManager.default.isExecutableFile(atPath: launchPath) else {
            throw ShellError.invalidExecutable(path: launchPath)
        }
        
        launch()
    }
    
    func tryFinishing() throws {
        
        self.waitUntilExit()
        
        guard self.terminationStatus == 0 else {
            throw ShellError.returnedErrorCode(command: commandAsString(), errorcode: Int(terminationStatus))
        }
    }
    
    private func commandAsString() -> String {
        let path = launchPath ?? ""
        return (arguments ?? []).reduce(path) { (result: String, arg: String) in
            return result + " " + arg
        }
    }
}
