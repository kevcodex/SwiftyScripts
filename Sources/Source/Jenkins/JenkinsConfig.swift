//
//  JenkinsConfig.swift
//  Source
//
//  Created by Kevin Chen on 12/28/18.
//

import Foundation

/// The associated build number with the target
typealias TargetBuildMapping = [String: JenkinsStartBuildNumber]

struct JenkinsConfig: Decodable {
    let credentials: JenkinsCredentials
    let delayBetweenBuilds: Int
    let label: Label
    var schemes: [Scheme]
    
    mutating func updateAllSchemes(version: String) {
        for index in schemes.indices {
            schemes[index].version = version
        }
    }
    
    mutating func updateAllBuildNumbers(with mapping: TargetBuildMapping) {
        for index in schemes.indices {
            guard let newValue = mapping[schemes[index].target] else {
                continue
            }
            schemes[index].startBuildNumber = newValue
        }
    }
    
    mutating func updateAllBuildNumberSources(_ source: JenkinsStartBuildNumber.Source) {
        for index in schemes.indices {
            schemes[index].startBuildNumber?.source = source
        }
    }
    
    /// Check to make sure all schemes have a valid start build number
    func hasValidBuildNumbers() -> Bool {
        for scheme in schemes {
            
            if scheme.startBuildNumber == nil {
                return false
            }
            
            if let startBuildNumber = scheme.startBuildNumber,
                startBuildNumber.value.isEmpty {
                return false
            }
        }
        
        return true
    }
}

extension JenkinsConfig {
    
    /// The parameters set for the job
    struct Scheme: Decodable {
        let target: String
        
        // Can be determined by either config or checking last builds
        var startBuildNumber: JenkinsStartBuildNumber?
        
        // Is set by console rather than config
        var version: String?
        
        // Optional values (if not provided, jenkins will use set default values)
        let configuration: String?
        let xcodeVersion: String?
        let shouldDeploy: Bool?
        let shouldDistribute: Bool?
        let shouldReleaseDSYMS: Bool?
        let shouldReduceBuilds: Bool?
        let shouldNotifySlack: Bool?
        let isSubmissionCandidate: Bool?
        let knownIssues: String?
        
        var instancesAsDictionary: [String: Any] {
            
            var dictionary: [String: Any] = [ParamKeys.scheme: target]
            
            if let startBuildNumber = startBuildNumber {
                dictionary[ParamKeys.startBuildNumber] = startBuildNumber.value
            }
            
            if let version = version {
                dictionary[ParamKeys.version] = version
            }
            
            if let configuration = configuration {
                dictionary[ParamKeys.configuration] = configuration
            }
            
            if let xcodeVersion = xcodeVersion {
                dictionary[ParamKeys.xcodeVersion] = xcodeVersion
            }
            
            if let shouldDeploy = shouldDeploy {
                dictionary[ParamKeys.deploy] = shouldDeploy
            }
            
            if let shouldDistribute = shouldDistribute {
                dictionary[ParamKeys.distribute] = shouldDistribute
            }
            
            if let shouldReleaseDSYMS = shouldReleaseDSYMS {
                dictionary[ParamKeys.dsyms] = shouldReleaseDSYMS
            }
            
            if let shouldReduceBuilds = shouldReduceBuilds {
                dictionary[ParamKeys.reduceBuilds] = shouldReduceBuilds
            }
            
            if let shouldNotifySlack = shouldNotifySlack {
                dictionary[ParamKeys.notifySlack] = shouldNotifySlack
            }
            
            if let isSubmissionCandidate = isSubmissionCandidate {
                dictionary[ParamKeys.submissionCandidate] = isSubmissionCandidate
            }
            
            if let knownIssues = knownIssues {
                dictionary[ParamKeys.knownIssues] = knownIssues
            }
            
            return dictionary
        }
        
        /// Init with only mandatory values with rest set as nil
        /// Jenkins will use set default values for nil values
        init(scheme: String,
             version: String,
             startBuildNumber: JenkinsStartBuildNumber,
             configuration: String? = nil,
             xcodeVersion: String? = nil,
             shouldDeploy: Bool? = nil,
             shouldDistribute: Bool? = nil,
             shouldReleaseDSYMS: Bool? = nil,
             shouldReduceBuilds: Bool? = nil,
             shouldNotifySlack: Bool? = nil,
             isSubmissionCandidate: Bool? = nil,
             knownIssues: String? = nil) {
            
            self.target = scheme
            self.version = version
            self.startBuildNumber = startBuildNumber
            self.configuration = configuration
            self.xcodeVersion = xcodeVersion
            self.shouldDeploy = shouldDeploy
            self.shouldDistribute = shouldDistribute
            self.shouldReleaseDSYMS = shouldReleaseDSYMS
            self.shouldReduceBuilds = shouldReduceBuilds
            self.shouldNotifySlack = shouldNotifySlack
            self.isSubmissionCandidate = isSubmissionCandidate
            self.knownIssues = knownIssues
        }
        
        /// Init with the jenkins default values
        init(scheme: String,
             version: String,
             startBuildNumber: JenkinsStartBuildNumber,
             configuration: String = "all",
             xcodeVersion: String = "10.1",
             shouldDeploy: Bool = true,
             shouldDistribute: Bool = true,
             shouldReleaseDSYMS: Bool = true,
             shouldReduceBuilds: Bool = true,
             shouldNotifySlack: Bool = true,
             isSubmissionCandidate: Bool = false,
             knownIssues: String = "N/A") {
            
            self.target = scheme
            self.version = version
            self.startBuildNumber = startBuildNumber
            self.configuration = configuration
            self.xcodeVersion = xcodeVersion
            self.shouldDeploy = shouldDeploy
            self.shouldDistribute = shouldDistribute
            self.shouldReleaseDSYMS = shouldReleaseDSYMS
            self.shouldReduceBuilds = shouldReduceBuilds
            self.shouldNotifySlack = shouldNotifySlack
            self.isSubmissionCandidate = isSubmissionCandidate
            self.knownIssues = knownIssues
        }
    }
}

extension JenkinsConfig {
    
    /// Params related to the label. Looks like {prefix}_{frontdoor}_{version}.{startBuildNumber}-{endBuildNumber} e.g. "DCGPD_FOXNation_3.12.706-708"
    struct Label: Decodable {
        let prefix: String
        let numberOfConfigurations: Int
    }
}

extension JenkinsConfig {
    struct ParamKeys {
        static let scheme = "SCHEME"
        static let version = "VERSION"
        static let startBuildNumber = "START_BUILD_NUMBER"
        static let configuration = "CONFIGURATION"
        static let xcodeVersion = "XCODE_VERSION"
        static let deploy = "DEPLOY"
        static let distribute = "DISTRIBUTE"
        static let dsyms = "DSYMS"
        static let reduceBuilds = "REDUCE_BUILDS"
        static let notifySlack = "NOTIFY_SLACK"
        static let submissionCandidate = "SUBMISSION_CANDIDATE"
        static let knownIssues = "KNOWN_ISSUES"
        private init() {}
    }
}
