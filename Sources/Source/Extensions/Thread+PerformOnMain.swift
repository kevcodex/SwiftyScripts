//
//  Thread+PerformOnMain.swift
//  Source
//
//  Created by Kevin Chen on 12/26/18.
//

import Foundation

extension Thread {
    static func performOnMain(_ block: () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync {
                block()
            }
        }
    }
}
