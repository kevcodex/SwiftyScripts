//
//  StartExecutable.swift
//  Source
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation
import ScriptHelpers
import MiniNe

// TODO: Look into seperating executables rather than arguments like jenkins only
/// The action to execute the script.
struct StartExecutable: Executable {
    var argumentString: String {
        return "start"
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
        let previousVersionArgument = PreviousVersionArgument()
        let directoryArgument = DirectoryArgument()
        let postPRArgument = PostPRArgument()
        let jenkinsOnlyArgument = JenkinsOnlyArgument()
        let jenkinsOffArgument = JenkinsOffArgument()
        let prettyArgument = PrettyArgument()
        let noInputArgument = NoInputArgument()
        let noBitbucketArgument = NoBitbucketRedirectArgument()
        let userArgument = UserArgument()
        
        let argumentDictionary: [String: Argument] =
            [versionArgument.argumentName: versionArgument,
             previousVersionArgument.argumentName: previousVersionArgument,
             directoryArgument.argumentName: directoryArgument,
             postPRArgument.argumentName: postPRArgument,
             jenkinsOnlyArgument.argumentName: jenkinsOnlyArgument,
             jenkinsOffArgument.argumentName: jenkinsOffArgument,
             prettyArgument.argumentName: prettyArgument,
             noInputArgument.argumentName: noInputArgument,
             noBitbucketArgument.argumentName: noBitbucketArgument,
             userArgument.argumentName: userArgument
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
        
        // MARK: Handle Arguments
        if argumentParser.argumentsIsEmpty()  {
            Console.showHelp()
            Darwin.exit(1)
        }
        
        // Get values of arguments
        guard let versionArg: VersionArgument = argumentParser.retrieveArgument(string: versionArgument.argumentName),
            let version = versionArg.value else {
                Console.writeMessage("Skewed or no version specified", styled: .red)
                Darwin.exit(1)
        }
        
        // If there is a previous verion it will pull from that version.
        var previousReleaseBranch: Branch?
        if let previousVersionArgument: PreviousVersionArgument = argumentParser.retrieveArgument(string: previousVersionArgument.argumentName),
            let previousVersionString = previousVersionArgument.value {
            previousReleaseBranch = Branch(type: .release, version: previousVersionString)
        }
        
        var runPostOnly = false
        if let _: PostPRArgument = argumentParser.retrieveArgument(string: postPRArgument.argumentName) {
            runPostOnly = true
        }
        
        var runJenkinsOnly = false
        if let _: JenkinsOnlyArgument = argumentParser.retrieveArgument(string: jenkinsOnlyArgument.argumentName) {
            runJenkinsOnly = true
        }
        
        var shouldRunJenkins = true
        if let _: JenkinsOffArgument = argumentParser.retrieveArgument(string: jenkinsOffArgument.argumentName) {
            
            guard runJenkinsOnly == false else {
                Console.writeMessage("You can't run jenkins only and turn off jenkins", styled: .red)
                Darwin.exit(1)
            }
            
            shouldRunJenkins = false
        }
        
        var runPretty = false
        if let _: PrettyArgument = argumentParser.retrieveArgument(string: prettyArgument.argumentName) {
            
            if let prettyCheckCommand = AnyCommand(rawStringInput: "which xcpretty"),
                CommandHelper.runCommandSilently(prettyCheckCommand) {
                runPretty = true
            } else {
                Console.writeMessage("It doesn't seem you have xcpretty installed! You can install with \"gem install xcpretty\"", styled: .red)
                Darwin.exit(1)
            }
        }
        
        var shouldRequestInput = true
        if let _: NoInputArgument = argumentParser.retrieveArgument(string: noInputArgument.argumentName) {
            shouldRequestInput = false
        }
        
        var shouldRedirectToBitbucket = true
        if let _: NoBitbucketRedirectArgument = argumentParser.retrieveArgument(string: noBitbucketArgument.argumentName) {
            shouldRedirectToBitbucket = false
        }
        
        var currentDirectory = FileManager.default.currentDirectoryPath
        if let directoryArgument: DirectoryArgument = argumentParser.retrieveArgument(string: directoryArgument.argumentName),
            let directoryValue = directoryArgument.value  {
            currentDirectory = directoryValue
            
            CommandHelper.changeDirectory(to: currentDirectory)
        }
        
        let foxNowPath = currentDirectory + "/FOXNOW.xcodeproj"
        guard FileManager.default.fileExists(atPath: foxNowPath) else {
            Console.writeMessage("Path: \(foxNowPath) does not contain FOXNOW project.", styled: .red)
            Darwin.exit(1)
        }
        
        // MARK: Retrieve Plist
        // If running from xcode make sure to set custom working path in edit scheme -> options
        
        let configPath = currentDirectory + "/swiftyscripts/config/config.plist"
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            Console.writeMessage("Directory does not have config, please create a config at path '/swiftyscripts/config/config.plist'.", styled: .red)
            Darwin.exit(1)
        }
        
        let url = URL(fileURLWithPath: configPath)
        let dictionary = NSDictionary(contentsOf: url) as? [String: Any]
        
        // MARK: Define Branches
        let releaseBranch = Branch(type: .release, version: version)
        let teamMergeBranch = Branch(type: .teamMerge, version: version)
        guard let developBranchesToRun = SetupHelper.createBranches(from: dictionary, version: version) else {
            Console.writeMessage("Skewed, missing, or unspecified branch type", styled: .red)
            Darwin.exit(1)
        }
        
        var branchList = ""
        for branch in developBranchesToRun {
            branchList += "    \(branch) \n"
        }
        
        // MARK: Define Targets
        guard let targetsToRun = SetupHelper.createTargets(from: dictionary) else {
            Console.writeMessage("Skewed, missing, or unspecified target type", styled: .red)
            Darwin.exit(1)
        }
        
        var targetsList = ""
        for target in targetsToRun {
            targetsList += "    Target: \(target) \n"
        }
        
        // MARK: Get user
        var user = ""
        if let userArgument: UserArgument = argumentParser.retrieveArgument(string: userArgument.argumentName), let value = userArgument.value {
            user = value
        }
        
        // MARK: Get slack info
        let slackInfo = SetupHelper.createSlackInfo(from: dictionary)
        var slackDescription = "Slack: N/A"
        if let slackInfo = slackInfo {
            slackDescription =
            """
            Slack:
                Channel: \(slackInfo.channel)
                Path: \(slackInfo.path)
            """
            
            slackController.team = SlackTeam(channel: slackInfo.channel, path: slackInfo.path)
        }
        
        // MARK: - Confirm Selection
        Console.writeMessage(
            """
            Will perform Team Merge with parameters:
            
            Working Directory: \(currentDirectory)
            Target Version: \(version),
            Previous Version: \(previousReleaseBranch?.version ?? "nil")
            Run Post PR Only: \(runPostOnly)
            Will Run Jenkins: \(shouldRunJenkins)
            Run Jenkins Only: \(runJenkinsOnly)
            Run xcPretty: \(runPretty)
            Will Redirect To Bitbucket: \(shouldRedirectToBitbucket)
            User: \(user.nonEmpty ?? "Anonymous")
            \(slackDescription)
            Branches:
            \(branchList)
            Targets:
            \(targetsList)\n
            """, styled: .blue
        )
        
        // MARK: - START!
        // MARK: Accept Parameters
        
        Console.waitForInputIfNeeded(shouldRequest: shouldRequestInput, question: "Run Team Merge with these parameters above? (y/n) ", invalidText: "Invalid Input", validInputs: ["y"], exitInputs: ["n"])
        
        slackController.slackUser = SlackUser(from: user)
        
        slackController.postStartMessage { result in
            
            switch result {
            case .success:
                Console.writeMessage("Successfully notified slack! \n", styled: .blue)
            case .failure(let error):
                Console.writeWarning(error)
            }
        }
        
        if runJenkinsOnly,
            shouldRunJenkins {
            runJenkins(with: dictionary, version: version, shouldRequestInput: shouldRequestInput)
            return
        }
        
        // MARK: - Merge branches to Team Merge
        
        if !runPostOnly {
            
            // MARK: Checkout Team Merge Branch
            Console.writeMessage("**Checking Out \(teamMergeBranch.path) Branch...")
            let checkOutCommand = GitCommand(arguments: [.checkout(branch: teamMergeBranch.path)])
            CommandHelper.runCommand(checkOutCommand)
            
            // MARK: Pull Team Merge Self
            Console.writeMessage("**Pulling \(teamMergeBranch.path)...")
            let pullCommand = GitCommand(arguments: [.pull(branch: nil)])
            CommandHelper.runCommand(pullCommand)
            
            // MARK: Pull From Previous Version
            if let previousReleaseBranch = previousReleaseBranch {
                Console.writeMessage("**Pulling from \(previousReleaseBranch.path)...")
                let pullCommand = GitCommand(arguments: [.pull(branch: previousReleaseBranch.path)])
                CommandHelper.runCommand(pullCommand)
            }
            
            // MARK: Pull all branches into TM branch
            for branch in developBranchesToRun {
                
                Console.writeMessage("**Pulling from \(branch.path) into \(teamMergeBranch.path)...")
                
                let pullCommand = GitCommand(arguments: [.pull(branch: branch.path)])
                pullCommand.run() { result in
                    switch result {
                    case .success(let message):
                        Console.writeMessage("Command Ran Successfully - " + message + "\n", styled: .blue)
                    case .failure(let error):
                        let message = "Error: \(error) \n" + " **THERE MIGHT BE A MERGE CONFLICT FROM BRANCH: \(branch.path), please fix if there is one and run script again** \n"
                        self.exit(1, with: message)
                    }
                }
            }
            
            // MARK: Xcode build
            
            // Remove pod lock first
            Console.writeMessage("**Removing PodFile...")
            let removePodLockCommand = AnyCommand(commandString: "rm", arguments: ["-rf", "Podfile.lock"])
            CommandHelper.runAndPrintCommand(removePodLockCommand)
            
            // Install new pod file
            Console.writeMessage("**Installing CocoaPods...")
            let podInstallCommand = AnyCommand(commandString: "pod", arguments: ["install"])
            let podUpdateCommand = AnyCommand(commandString: "pod", arguments: ["update"])
            
            CommandHelper.runAndPrintCommand(podInstallCommand) { result in
                switch result {
                case .success:
                    Console.writeMessage("Command Ran Successfully! \n", styled: .blue)
                case .failure:
                    CommandHelper.runAndPrintCommand(podUpdateCommand)
                }
            }
            
            // Build all targets
            for target in targetsToRun {
                
                Console.writeMessage("**Building \(target)...")
                // xcodebuild -workspace FOXNOW.xcworkspace -configuration QA -scheme NatGeo -sdk appletvos11.2
                let buildCommand = XcodeBuildCommand(arguments: [.workspace(named: "FOXNOW.xcworkspace"),
                                                                 .sdk(type: .tvOSSimulator),
                                                                 .configuration(type: .qa),
                                                                 .scheme(named: target),
                                                                 .clean,
                                                                 .build,
                                                                 .modernSystem(shouldUse: false)])
                
                if runPretty,
                    let xcprettyRun = AnyCommand(rawStringInput: buildCommand.commandAsString() + " " + "| xcpretty && exit ${PIPESTATUS[0]}") {
                    
                    CommandHelper.runAndPrintBashCommand(xcprettyRun)
                } else {
                    CommandHelper.runAndPrintCommand(buildCommand)
                }
            }
            
            // MARK: Push Team Merge
            Console.writeMessage("**Pushing \(teamMergeBranch.path)...")
            let pushTMCommand = GitCommand(arguments: [.push])
            CommandHelper.runCommand(pushTMCommand)
            
            // MARK: Check Diff for team merge -> release
            Console.writeMessage("**Checking Diff, please merge into release...")
            
            let runner = SwiftScriptRunner()
            runner.lock()
            
            var count = 0
            
            // Check diff between release and team merge to see if it has been merged in yet
            DiffChecker(branch1: teamMergeBranch.remotePath,
                        branch2: releaseBranch.remotePath,
                        restarting: { message, timeTillCheck in
                            
                            count += 1
                            Console.writeMessage(message + "\n" + "** Attempt number: \(count). Still havn't merged, please merge into release, checking again in \(timeTillCheck) sec...", styled: .purple)
                            
            },
                        finished: { success, error in
                            
                            if success {
                                Console.writeMessage("**Merged! Lets continue!", styled: .blue)
                                runner.unlock()
                            } else {
                                var message = ""
                                if let error = error {
                                    message = "Error: \(error)"
                                }
                                self.exit(1, with: message)
                            }
            })
            
            if shouldRedirectToBitbucket {
                Console.writeMessage("**Opening bitbucket PR creation...")
                let controller = BitbucketController()
                
                do {
                    try controller.redirectToBitbucket(sourceBranch: teamMergeBranch.path, targetBranch: releaseBranch.path)
                } catch {
                    Console.writeMessage(error)
                }
            }
            
            // MARK: Notify slack for PR
            
            Console.writeMessage("**Notifing Slack...")
            
            let parameters = BitbucketController.parameters(for: teamMergeBranch.path, targetBranch: releaseBranch.path)

            slackController.postPRMessage(bitbucketParameters: parameters) { result in
                
                switch result {
                case .success:
                    Console.writeMessage("Successfully notified slack! \n", styled: .blue)
                case .failure(let error):
                    Console.writeWarning(error)
                }
            }
            
            runner.wait()
        }
        
        // MARK: - Post-PR
        
        // MARK: Remove any local change anomolies
        Console.writeMessage("**Discarding Potential Local Changes...")
        let discardCommand = GitCommand(arguments: [.reset])
        CommandHelper.runCommand(discardCommand)
        
        // MARK: Fetch
        Console.writeMessage("**Fetching...")
        let fetchCommand = GitCommand(arguments: [.fetchAll])
        CommandHelper.runCommand(fetchCommand)
        
        for branch in developBranchesToRun {
            
            // MARK: Checkout
            Console.writeMessage("**Changing branch to \(branch.path)")
            let checkoutCommand = GitCommand(arguments: [.checkout(branch: branch.path)])
            CommandHelper.runCommand(checkoutCommand)
            
            // MARK: Pull Self
            Console.writeMessage("**Pulling \(branch.path)...")
            var pullCommand = GitCommand(arguments: [.pull(branch: nil)])
            CommandHelper.runCommand(pullCommand)
            
            // MARK: Pull from Release
            Console.writeMessage("**Pulling from \(releaseBranch.path)...")
            pullCommand = GitCommand(arguments: [.pull(branch: releaseBranch.path)])
            CommandHelper.runCommand(pullCommand)
            
            // MARK: Push
            Console.writeMessage("**Pushing \(branch.path)...")
            let pushCommand = GitCommand(arguments: [.push])
            CommandHelper.runCommand(pushCommand)
            
        }
        
        Console.writeMessage("Success! Finished Team Merge! You owe Kevin 5,000,000 PC now", styled: .green)
        
        slackController.postFinishedTeamMergeMessage { result in
            
            switch result {
            case .success:
                Console.writeMessage("Successfully notified slack! \n", styled: .blue)
            case .failure(let error):
                Console.writeWarning(error)
            }
        }
        
        if shouldRunJenkins {
            runJenkins(with: dictionary, version: version, shouldRequestInput: shouldRequestInput)
        }
    }
    
    /// Exits the script with a message to console and slack.
    /// Should just be used when script is actually running.
    private func exit(_ int: Int32, with message: String) -> Never {
        
        Console.writeMessage(message, styled: .red)
        
        slackController.postErrorMessage(errorMessage: message) { result in
            
            switch result {
            case .success:
                Console.writeMessage("Successfully notified slack! \n", styled: .blue)
            case .failure(let error):
                Console.writeWarning(error)
            }
        }
        
        Darwin.exit(int)
    }
    
    // MARK: - Run Jenkins
    private func runJenkins(with configDictionary: [String: Any]?, version: String, shouldRequestInput: Bool) {
        
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
