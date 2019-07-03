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
struct StartExecutable: Executable, SlackMessageDeliverable {
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
        let jenkinsOffArgument = JenkinsOffArgument()
        let prettyArgument = PrettyArgument()
        let noInputArgument = NoInputArgument()
        let noBitbucketArgument = NoBitbucketRedirectArgument()
        let userArgument = UserArgument()
        
        let argumentDictionary: [String: Argument] =
            [VersionArgument.argumentName: versionArgument,
             PreviousVersionArgument.argumentName: previousVersionArgument,
             DirectoryArgument.argumentName: directoryArgument,
             PostPRArgument.argumentName: postPRArgument,
             JenkinsOffArgument.argumentName: jenkinsOffArgument,
             PrettyArgument.argumentName: prettyArgument,
             NoInputArgument.argumentName: noInputArgument,
             NoBitbucketRedirectArgument.argumentName: noBitbucketArgument,
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
        
        // MARK: Handle Arguments
        if argumentParser.argumentsIsEmpty()  {
            Console.showHelp()
            Darwin.exit(1)
        }
        
        // Get values of arguments
        guard let versionArg: VersionArgument = argumentParser.retrieveArgument(),
            let version = versionArg.value else {
                Console.writeMessage("Skewed or no version specified", styled: .red)
                Darwin.exit(1)
        }
        
        // If there is a previous version it will pull from that version.
        var previousReleaseBranch: Branch?
        if let previousVersionArgument: PreviousVersionArgument = argumentParser.retrieveArgument(),
            let previousVersionString = previousVersionArgument.value {
            
            previousReleaseBranch = Branch(type: .release, version: previousVersionString)
            
            guard let versionComponent = Version(string: version), let previousVersionComponent = Version(string: previousVersionString) else {
                Console.writeMessage("Invalid Version", styled: .red)
                Darwin.exit(1)
            }
            
            guard versionComponent > previousVersionComponent else {
                Console.writeMessage("Version is less than previous version, please ensure Version is larger.", styled: .red)
                Darwin.exit(1)
            }
        }
        
        var runPostOnly = false
        if let _: PostPRArgument = argumentParser.retrieveArgument() {
            runPostOnly = true
        }
        
        var shouldRunJenkins = true
        if let _: JenkinsOffArgument = argumentParser.retrieveArgument() {
            
            shouldRunJenkins = false
        }
        
        var runPretty = false
        if let _: PrettyArgument = argumentParser.retrieveArgument() {
            
            if let prettyCheckCommand = AnyCommand(rawStringInput: "which xcpretty"),
                CommandHelper.runCommandSilently(prettyCheckCommand) {
                runPretty = true
            } else {
                Console.writeMessage("It doesn't seem you have xcpretty installed! You can install with \"gem install xcpretty\"", styled: .red)
                Darwin.exit(1)
            }
        }
        
        var shouldRequestInput = true
        if let _: NoInputArgument = argumentParser.retrieveArgument() {
            shouldRequestInput = false
        }
        
        var shouldRedirectToBitbucket = true
        if let _: NoBitbucketRedirectArgument = argumentParser.retrieveArgument() {
            shouldRedirectToBitbucket = false
        }
        
        var currentDirectory = FileManager.default.currentDirectoryPath
        if let directoryArgument: DirectoryArgument = argumentParser.retrieveArgument(),
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
        if let userArgument: UserArgument = argumentParser.retrieveArgument(),
            let value = userArgument.value {
            user = value
        }
        
        // MARK: Get slack info
        setupSlackController(from: dictionary, slackUser: user)
        
        var slackDescription = "Slack: N/A"
        if let slackChannel = slackController.team?.channel,
            let slackPath = slackController.team?.path {
            slackDescription =
            """
            Slack:
                Channel: \(slackChannel)
                Path: \(slackPath)
            """
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
        
        slackController.postStartMessage { result in
            
            switch result {
            case .success:
                Console.writeMessage("Successfully notified slack! \n", styled: .blue)
            case .failure(let error):
                Console.writeWarning(error)
            }
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
            let buildExecutable = BuildExecutable()
            buildExecutable.run(targetsToRun: targetsToRun, runPretty: runPretty)
            
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
            let jenkinsExecutable = JenkinsExecutable()
            jenkinsExecutable.run(with: dictionary, version: version, shouldRequestInput: shouldRequestInput)
        }
    }
}
