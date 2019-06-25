//
//  Console+Extensions.swift
//  Source
//
//  Created by Kevin Chen on 1/11/19.
//

import Foundation
import ScriptHelpers

extension Console {
    /// Ask for input if shouldRequest is true
    static func waitForInputIfNeeded(shouldRequest: Bool, question: String, invalidText: String, validInputs: [String], exitInputs: [String]) {
        
        if shouldRequest {
            waitForValidInput(question: question, invalidText: invalidText, validInputs: validInputs, exitInputs: exitInputs)
        }
    }
}

extension Console {
    static func writeWarning(_ error: Error) {
        writeMessage("Warning: \(error.localizedDescription)", styled: .yellow)
    }
}
