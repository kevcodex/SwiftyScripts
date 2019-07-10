//
//  Argument.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 6/22/18.
//

import Foundation

/// Model for an argument that someone defines
protocol Argument: HelpDescription {
    /// The raw string of the arugment that the user inputs. E.g. "v" or "help"
    static var argumentName: String { get }
    
    var requiresValue: Bool { get }
    var value: String? { get set }
}

