//
//  SetupHelper.swift
//  Run
//
//  Created by Kevin Chen on 6/30/18.
//

import Foundation

/// Helper to help setup script
struct SetupHelper {
    
    private init() {}
    
    static func projectName(from dictionary: [String: Any]?) -> String? {
        
        guard let dictionary = dictionary else {
            return nil
        }
        
        return dictionary[Keys.projectName] as? String        
    }
    
    static func bitbucketURL(from dictionary: [String: Any]?) -> String? {
            
            guard let dictionary = dictionary else {
                return nil
            }
            
            return dictionary[Keys.bitbucketURL] as? String
        }
    
    static func createBranches(from dictionary: [String: Any]?, version: String) -> [Branch]? {
        
        guard let dictionary = dictionary else {
            return nil
        }
        
        let rawBranches = dictionary[Keys.branches] as? [String]
        
        return rawBranches?.compactMap { Branch(from: $0, version: version) }
    }
    
    static func createTargets(from dictionary: [String: Any]?) -> [String]? {
        
        guard let dictionary = dictionary else {
            return nil
        }
        
        let rawBranches = dictionary[Keys.targets] as? [String]
        
        return rawBranches
    }
    
    static func createJenkinsConfig(from dictionary: [String: Any], version: String) -> JenkinsConfig? {

        guard let jenkinsDictionary = dictionary[Keys.jenkins] as? [String: Any] else {
            return nil
        }
        
        do {
            let plistDecoder = PropertyListDecoder()
            let data = try PropertyListSerialization.data(fromPropertyList: jenkinsDictionary, format: .xml, options: 0)
            var jenkinsConfig = try plistDecoder.decode(JenkinsConfig.self, from: data)
            
            jenkinsConfig.updateAllSchemes(version: version)
            jenkinsConfig.updateAllBuildNumberSources(.plistConfig)
            
            return jenkinsConfig
        } catch {
            print(error)
            return nil
        }
    }
    
    static func createSlackInfo(from dictionary: [String: Any]?) -> SlackInfo? {
        
        guard let slackDictionary = dictionary?[Keys.slack] as? [String: Any] else {
            return nil
        }
        
        do {
            let plistDecoder = PropertyListDecoder()
            let data = try PropertyListSerialization.data(fromPropertyList: slackDictionary, format: .xml, options: 0)
            return try plistDecoder.decode(SlackInfo.self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    
    static func createPurgerConfig(from url: URL) -> PurgerConfig? {
        
        do {
            let data = try Data(contentsOf: url)
            let plistDecoder = PropertyListDecoder()
            return try plistDecoder.decode(PurgerConfig.self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    
    static func createConfig(from url: URL) -> Config? {
        
        do {
            let data = try Data(contentsOf: url)
            let plistDecoder = PropertyListDecoder()
            let config = try plistDecoder.decode(Config.self, from: data)
            
            return config
        } catch {
            print(error)
            return nil
        }
    }
}

private extension SetupHelper {
    struct Keys {
        
        static let projectName = "project"
        static let bitbucketURL = "bitbucketURL"
        static let targets = "TargetsToRun"
        static let branches = "BranchesToRun"
        static let jenkins = "Jenkins"
        static let slack = "Slack"
        
        private init() {}
    }
}
