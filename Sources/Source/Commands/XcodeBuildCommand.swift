//
//  XcodeBuildCommand.swift
//  TeamMergeAutomation
//
//  Created by Kevin Chen on 3/27/18.
//

import Foundation


struct XcodeBuildCommand: Command {

    enum XcodeBuildType {
        case workspace(named: String)
        case sdk(type: SDKType)
        case scheme(named: String)
        case configuration(type: ConfigurationType)
        case modernSystem(shouldUse: Bool)
        case clean
        case build
        case test
        
        enum SDKType: String {
            case iOS = "iphoneos"
            case iOSSimulator = "iphonesimulator"
            case tvOS = "appletvos"
            case tvOSSimulator = "appletvsimulator"
        }
        
        enum ConfigurationType: String {
            case qa = "QA"
            case staging = "Staging"
            case dev = "Dev"
            case prod = "AppStore"
        }
    }
    
    typealias Argument = XcodeBuildType
    
    var commandString: String {
        return "xcodebuild"
    }
    
    var arguments: [Argument]
    
    func argumentsAsStringArray() -> [String] {
        var string = ""
        
        for argument in arguments {
            switch argument {
                
            case .workspace(let named):
                string += "-workspace \(named)"
            case .sdk(let type):
                string += "-sdk \(type.rawValue)"
            case .scheme(let named):
                string += "-scheme \(named)"
            case .configuration(let type):
                string += "-configuration \(type.rawValue)"
            case .modernSystem(let shouldUse):
                let bool = shouldUse ? "YES" : "NO"
                string += "-UseModernBuildSystem=\(bool)"
            case .clean:
                string += "clean"
            case .build:
                string += "build"
            case .test:
                string += "test"
            }
            
            string += " "
        }
        
        let stringArray = string.components(separatedBy: " ")
        let noEmptyStrings = stringArray.filter { !$0.isEmpty }
        
        return noEmptyStrings
    }
}
