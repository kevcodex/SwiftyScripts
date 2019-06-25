//
//  Collection+NonEmpty.swift
//  Source
//
//  Created by Kevin Chen on 12/26/18.
//

import Foundation

extension Collection {
    public var nonEmpty: Self? {
        return !isEmpty ? self : nil
    }
}

// MARK: - Support collection index boundary check.
extension Collection {
    private subscript(safe index: Index) -> Iterator.Element? {
        if indices.contains(index) {
            return self[index]
        } else {
            assertionFailure("Index \(index) out of boundary")
            return nil
        }
    }
    
    /// A safe function to get element of Collection at index path.
    ///
    /// - Parameter index: Index of element in a collection.
    /// - Returns: Element at a given index. If an index is out of boundary of a collection it will return nil and an assertionFailure.
    func safe(index: Index) -> Iterator.Element? {
        return self[safe: index]
    }
}
