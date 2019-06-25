//
//  RunError.swift
//  CommandsTestPackageDescription
//
//  Created by Kevin Chen on 3/26/18.
//

import Foundation

//struct RunError {
//    let code: Int
//    let message: String
//}

enum RunError: Error {
    case shellError(ShellError)
    case other(Error)
}
