//
//  Version.swift
//  
//
//  Created by Kevin Chen on 7/1/19.
//

import Foundation

/// An object for seperating version components like 3.14.1 for easier comparision 
struct Version {
    let components: [Int]
    
    init?(string: String) {
        let stringComponents = string.components(separatedBy: ".")
        
        var components = [Int]()
        for string in stringComponents {
            guard let int = Int(string) else {
                return nil
            }
            
            components.append(int)
        }
        
        guard !components.isEmpty else {
            return nil
        }
        
        self.components = components
    }
}

extension Version: Comparable {
    static func < (lhs: Version, rhs: Version) -> Bool {
        for (component1, component2) in zip(lhs.components, rhs.components) {
            
            if component1 == component2 {
                continue
            }
            
            return component1 < component2
        }
        
        return lhs.components.count < rhs.components.count
    }
}
