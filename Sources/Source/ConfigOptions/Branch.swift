//
//  Branch.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 3/27/18.
//

import Foundation

enum BranchType: String, Codable {
    case release
    case teamMerge
    case consumerGrowth
    case core
    case entitlements
    case fyc
}

struct Branch: Codable {
    
    let type: BranchType
    let version: String
    
    init(type: BranchType, version: String) {
        self.type = type
        self.version = version
    }
    
    init?(from string: String, version: String) {
        
        self.version = version
        
        switch string {
        case BranchType.core.rawValue:
            self.type = .core
        case BranchType.consumerGrowth.rawValue:
            self.type = .consumerGrowth
        case BranchType.entitlements.rawValue:
            self.type = .entitlements
        case BranchType.fyc.rawValue:
            self.type = .fyc
        default:
            return nil
        }
    }
    
    var path: String {
        
        switch type {
        case .release:
            return "release/\(version)"
        case .teamMerge:
            return "core/team_merge/\(version)"
        case .consumerGrowth:
            return "consumer_growth/develop/\(version)"
        case .core:
            return "core/develop/\(version)"
        case .entitlements:
            return "entitlements/develop/\(version)"
        case .fyc:
            return "for_your_consideration/develop/\(version)"
        }
    }
    
    var remotePath: String {
        return "remotes/origin/\(self.path)"
    }
}

extension Branch: Equatable {
    static func ==(lhs: Branch, rhs: Branch) -> Bool {
        return lhs.type == rhs.type && lhs.version == rhs.version
    }
}

extension Branch: CustomStringConvertible {
    var description: String {
        return "Branch: \(self.type.rawValue), version: \(self.version)"
    }
}

func createAllDevelopBranches(for version: String) -> [Branch] {
    let consumerGrowthBranch = Branch(type: .consumerGrowth, version: version)
    let coreBranch = Branch(type: .core, version: version)
    let entitlementsBranch = Branch(type: .entitlements, version: version)
//    let fycBranch = Branch(type: .fyc, version: version)
    
    let allBranches = [consumerGrowthBranch, coreBranch, entitlementsBranch]
    
    return allBranches
}

