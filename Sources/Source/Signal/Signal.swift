//
//  Signal.swift
//  Source
//
//  Created by Kevin Chen on 1/11/19.
//

import Foundation


struct Signal {
    
    // See https://en.wikipedia.org/wiki/Signal_(IPC)
    enum Category: CaseIterable {
        case hangup
        case interrupt
        case illegal
        case trap
        case abort
        case kill
        case alarm
        case termination
        
        var portableNumber: Int32 {
            switch self {
            case .hangup:
                return SIGHUP
            case .interrupt:
                return SIGINT
            case .illegal:
                return SIGILL
            case .trap:
                return SIGTRAP
            case .abort:
                return SIGABRT
            case .kill:
                return SIGKILL
            case .alarm:
                return SIGALRM
            case .termination:
                return SIGTERM
            }
        }
    }
    
    static func monitor(signal: Category, action: @escaping @convention(c) (Int32) -> Void) {
        
        var signalAction = sigaction(__sigaction_u: unsafeBitCast(action, to: __sigaction_u.self), sa_mask: 0, sa_flags: 0)
        let _ = withUnsafePointer(to: &signalAction) { actionPointer in
            sigaction(signal.portableNumber, actionPointer, nil)
        }
    }
    
    static func monitor(signal: Int32, action: @escaping @convention(c) (Int32) -> Void) {
        
        var signalAction = sigaction(__sigaction_u: unsafeBitCast(action, to: __sigaction_u.self), sa_mask: 0, sa_flags: 0)
        let _ = withUnsafePointer(to: &signalAction) { actionPointer in
            sigaction(signal, actionPointer, nil)
        }
        
        // better to use sigaction(2)
        //        signal(SIGINT, SIG_IGN)
        //
        //
        //        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        //        sigintSrc.setEventHandler {
        //            print("Got SIGINT")
        //            exit(0)
        //        }
        //        sigintSrc.resume()
    }
    
    /// Trigger a OS signal
    static func raise(signal: Category) {
        Darwin.raise(signal.portableNumber)
    }
}
