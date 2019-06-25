//
//  Result.swift
//  CommandsTestPackageDescription
//
//  Created by Kevin Chen on 3/26/18.
//

import Foundation

enum Result<T, Error: Swift.Error> {
    case success(T)
    case failure(Error)
    
    init(value: T) {
        self = .success(value)
    }
    
    init(error: Error) {
        self = .failure(error)
    }
    
    func unbox() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

extension Result where T == Void {
    
    static var success: Result {
        return .success(())
    }
}
