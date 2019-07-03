//
//  JenkinsExecutable.swift
//  
//
//  Created by Kevin Chen on 7/3/19.
//

import Foundation
import ScriptHelpers

struct JenkinsExecutable: Executable, SlackMessageDeliverable {
    var argumentString: String {
        "jenkins"
    }
    
    let slackController = SlackController()
    
    func run(arguments: [String]?) {
        guard let arguments = arguments,
            !arguments.isEmpty else {
                
                Console.writeMessage("No arguments specified. At a minimum you need to specify version to build (e.g. swiftyscripts start -v 3.10)", styled: .red)
                Darwin.exit(1)
        }
        
        // MARK: Define and Parse Arguments
        let versionArgument = VersionArgument()
        let directoryArgument = DirectoryArgument()
        let noInputArgument = NoInputArgument()
        let userArgument = UserArgument()
        
        let argumentDictionary: [String: Argument] =
            [VersionArgument.argumentName: versionArgument,
             DirectoryArgument.argumentName: directoryArgument,
             NoInputArgument.argumentName: noInputArgument,
             UserArgument.argumentName: userArgument
        ]
        
        let argumentParser = ArgumentParser(argumentsToParse: argumentDictionary)
        do {
            try argumentParser.parse(inputs: CommandLine.arguments)
        } catch ArgumentParser.ParserError.unknownArgument(let input) {
            // nothing For now
            Console.writeMessage("Undefined argument: \(input). You may need to define in Argument Parser", styled: .red)
            Darwin.exit(1)
        } catch ArgumentParser.ParserError.missingValue(let argument) {
            Console.writeMessage("Missing value for argument: \(argument)", styled: .red)
            Darwin.exit(1)
        } catch {
            Console.writeMessage("Unknown Error: \(error)", styled: .red)
            Darwin.exit(1)
        }
        
        // MARK: Retrieve Plist
        // If running from xcode make sure to set custom working path in edit scheme -> options
        
        var currentDirectory = FileManager.default.currentDirectoryPath
        if let directoryArgument: DirectoryArgument = argumentParser.retrieveArgument(),
            let directoryValue = directoryArgument.value  {
            currentDirectory = directoryValue
            
            CommandHelper.changeDirectory(to: currentDirectory)
        }
        
        let configPath = currentDirectory + "/swiftyscripts/config/config.plist"
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            Console.writeMessage("Directory does not have config, please create a config at path '/swiftyscripts/config/config.plist'.", styled: .red)
            Darwin.exit(1)
        }
        
        let url = URL(fileURLWithPath: configPath)
        let dictionary = NSDictionary(contentsOf: url) as? [String: Any]
        
        // MARK: Get Version
        guard let versionArg: VersionArgument = argumentParser.retrieveArgument(),
            let version = versionArg.value else {
                Console.writeMessage("Skewed or no version specified", styled: .red)
                Darwin.exit(1)
        }
        
        // MARK: Get should input
        var shouldRequestInput = true
        if let _: NoInputArgument = argumentParser.retrieveArgument() {
            shouldRequestInput = false
        }
        
        // MARK: Get user
        var user = ""
        if let userArgument: UserArgument = argumentParser.retrieveArgument(), let value = userArgument.value {
            user = value
        }
        
        setupSlackController(from: dictionary, slackUser: user)
        
        run(with: dictionary, version: version, shouldRequestInput: shouldRequestInput)
    }
    
    func run(with configDictionary: [String: Any]?, version: String, shouldRequestInput: Bool) {
        
        guard let configDictionary = configDictionary else {
            let message = "Missing or skewed plist config."
            exit(1, with: message)
        }
        
        guard var jenkinsConfig = SetupHelper.createJenkinsConfig(from: configDictionary, version: version) else {
            let message = "Something went wrong initializing jenkins config"
            exit(1, with: message)
        }
        
        let jenkinsController = JenkinsController(credentials: jenkinsConfig.credentials)
        
        if !jenkinsConfig.hasValidBuildNumbers() {
            
            Console.writeMessage("**No specified start build number in config, will attempt to get start build number based on last builds")
            
            var targetBuildMapping = TargetBuildMapping()
            
            let targets = jenkinsConfig.schemes.compactMap { $0.target }
            
            Console.writeMessage("**Fetching lastest build jobs info")
            
            jenkinsController.fetchLatestBuildNumbers(targets: targets) { (result) in
                switch result {
                case .success(let mapping):
                    Console.writeMessage("**Successfully fetched latest build info for targets \n",
                                         styled: .blue)
                    
                    targetBuildMapping = mapping.mapValues {
                        JenkinsStartBuildNumber(value: String($0 + jenkinsConfig.label.numberOfConfigurations),
                                                source: .jenkinsBuildInfoOnline)
                    }
                case .failure(let error):
                    let message = "Something went wrong fetching build numbers, error: \(error)"
                    self.exit(1, with: message)
                }
            }
            
            guard !targetBuildMapping.isEmpty else {
                let message = "Empty target build number mapping"
                exit(1, with: message)
            }
            
            // Use the config start build number if there is one present
            for scheme in jenkinsConfig.schemes {
                if let buildNumber = scheme.startBuildNumber {
                    targetBuildMapping[scheme.target] = buildNumber
                }
            }
            
            jenkinsConfig.updateAllBuildNumbers(with: targetBuildMapping)
        }
        
        Console.writeMessage("Will run jenkins deployment jobs with parameters:", styled: .blue)
        
        Console.writeMessage(
            """
            
            Delay Between Targets: \(jenkinsConfig.delayBetweenBuilds) seconds
            
            """, styled: .blue
        )
        
        for scheme in jenkinsConfig.schemes {
            
            guard let version = scheme.version else {
                let message = "Missing version in scheme for \(scheme.target)"
                Console.writeMessage("Missing version in scheme for \(scheme.target)", styled: .red)
                exit(1, with: message)
            }
            
            guard let startBuildNumber = scheme.startBuildNumber else {
                let message = "Missing start build number for \(scheme.target)"
                exit(1, with: message)
            }
            
            guard let startBuildNumberIntegar = Int(startBuildNumber.value) else {
                let message = "Start build number is not an integar for \(scheme.target)"
                exit(1, with: message)
            }
            
            let lastBuildNumber = startBuildNumberIntegar + jenkinsConfig.label.numberOfConfigurations - 1
            
            let labelDescription = "\(jenkinsConfig.label.prefix)_\(scheme.target)_\(version).\(startBuildNumber.value)-\(lastBuildNumber)"
            
            Console.writeMessage(
                """
                
                Scheme Target: \(scheme.target)
                Version: \(version)
                Start Build Number: \(startBuildNumber.value) (Set by \(startBuildNumber.source?.rawValue ?? "Unknown"))
                Label: \(labelDescription)
                Configuration: \(scheme.configuration ?? "Jenkins Default")
                Xcode Version: \(scheme.xcodeVersion ?? "Jenkins Default")
                Deploy: \(scheme.shouldDeploy?.description ?? "Jenkins Default")
                Distribute: \(scheme.shouldDistribute?.description ?? "Jenkins Default")
                DSYMS: \(scheme.shouldReleaseDSYMS?.description ?? "Jenkins Default")
                Reduce Builds: \(scheme.shouldReduceBuilds?.description ?? "Jenkins Default")
                Notify Slack: \(scheme.shouldNotifySlack?.description ?? "Jenkins Default")
                Submission Candidate: \(scheme.isSubmissionCandidate?.description ?? "Jenkins Default")
                Known Issues: \(scheme.knownIssues ?? "Jenkins Default")
                """, styled: .blue
            )
        }
        
        Console.waitForInputIfNeeded(shouldRequest: shouldRequestInput, question: "Run Jenkins job with these parameters above? (y/n)", invalidText: "Invalid Input", validInputs: ["y"], exitInputs: ["n"])
        
        slackController.postStartJenkinsMessage { result in
            
            switch result {
            case .success:
                Console.writeMessage("Successfully notified slack! \n", styled: .blue)
            case .failure(let error):
                Console.writeWarning(error)
            }
        }
        
        for (index, scheme) in jenkinsConfig.schemes.enumerated() {
            
            guard let version = scheme.version else {
                let message = "Missing version in scheme for \(scheme.target)"
                Console.writeMessage("Missing version in scheme for \(scheme.target)", styled: .red)
                exit(1, with: message)
            }
            
            guard let startBuildNumber = scheme.startBuildNumber else {
                let message = "Missing start build number for \(scheme.target)"
                exit(1, with: message)
            }
            
            guard let startBuildNumberIntegar = Int(startBuildNumber.value) else {
                let message = "Start build number is not an integar for \(scheme.target)"
                exit(1, with: message)
            }
            
            Console.writeMessage("**Starting Jenkins job for front door: \(scheme.target)")
            
            jenkinsController.startDeploymentBuild(with: scheme.instancesAsDictionary) { (result) in
                switch result {
                case .success:
                    Console.writeMessage("**Successfully started Jenkins job for front door: \(scheme.target) \n", styled: .blue)
                case .failure(let error):
                    let message = "Failed starting Jenkins job for front door: \(scheme.target), error: \(error)"
                    self.exit(1, with: message)
                }
            }
            
            // TODO: - Find a better way to handle if build is in queue, the description isn't set properly
            // Temporary set description after delay
            let setDescriptionBlock: () -> Void = {
                
                Console.writeMessage("**Setting description for: \(scheme.target)")
                let lastBuildNumber = startBuildNumberIntegar + jenkinsConfig.label.numberOfConfigurations - 1
                
                let description = "\(jenkinsConfig.label.prefix)_\(scheme.target)_\(version).\(startBuildNumber.value)-\(lastBuildNumber)"
                
                jenkinsController.addDescriptionToLastBuild(description: description) { (result) in
                    switch result {
                    case .success:
                        Console.writeMessage("**Successfully set description for front door: \(scheme.target) \n", styled: .blue)
                    case .failure(let error):
                        Console.writeMessage("WARNING: Failed to set description for: \(scheme.target), error: \(error)", styled: .yellow)
                    }
                }
            }
            
            if jenkinsConfig.schemes.count != (index + 1) {
                Console.writeMessage("**Waiting \(jenkinsConfig.delayBetweenBuilds) seconds to start next build...", styled: .blue)
                sleep(UInt32(jenkinsConfig.delayBetweenBuilds))
                
                setDescriptionBlock()
            } else {
                sleep(UInt32(100))
                setDescriptionBlock()
            }
        }
        
        Console.writeMessage("Success! Finished Running Jenkins Jobs! You owe Kevin 5,000,000 PC now", styled: .green)
        
        slackController.postFinishedJenkinsMessage { result in
            
            switch result {
            case .success:
                Console.writeMessage("Successfully notified slack! \n", styled: .blue)
            case .failure(let error):
                Console.writeWarning(error)
            }
        }
    }
}
