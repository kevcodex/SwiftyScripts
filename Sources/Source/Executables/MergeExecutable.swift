//
//  MergeExecutable.swift
//  Source
//
//  Created by Kevin Chen on 10/23/18.
//

import Foundation
import ScriptHelpers
import MiniNe

/// Perform a team merge
struct MergeExecutable: Executable, SlackMessageDeliverable {
    
    var argumentName: String {
        return "merge"
    }
    
    var description: String {
        return "Does a team merge"
    }
    
    let slackController: SlackController
    
    func run(arguments: [String]?) {
        // MARK: Define and Parse Arguments
        let arguments: [Argument] = [
            VersionArgument(),
            PreviousVersionArgument(),
            DirectoryArgument(),
            JenkinsOffArgument(),
            PrettyArgument(),
            NoInputArgument(),
            NoBitbucketRedirectArgument(),
            UserArgument(),
            HelpArgument()
        ]
        
        let argumentParser = parseArguments(arguments)
        
        // MARK: Handle Arguments
        if argumentParser.argumentsIsEmpty()  {
            showHelp(for: arguments)
            Console.writeMessage("Need to specify arguments like -v", styled: .red)
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
        
        // MARK: Retrieve Plist
        // If running from xcode make sure to set custom working path in edit scheme -> options
        
        let configPath = currentDirectory + "/swiftyscripts/config/config.plist"
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            Console.writeMessage("Directory does not have config, please create a config at path '/swiftyscripts/config/config.plist'.", styled: .red)
            Darwin.exit(1)
        }
        
        let url = URL(fileURLWithPath: configPath)
        let dictionary = NSDictionary(contentsOf: url) as? [String: Any]
        
        // MARK: Get Project Name
        guard let projectName = SetupHelper.projectName(from: dictionary) else {
            Console.writeMessage("Missing Project Name", styled: .red)
            Darwin.exit(1)
        }
        
        let projectPath = currentDirectory + "/\(projectName)"
        guard FileManager.default.fileExists(atPath: projectPath) else {
            Console.writeMessage("Path: \(projectPath) does not contain an xcode project.", styled: .red)
            Darwin.exit(1)
        }
        
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
            
            Project: \(projectName)
            Working Directory: \(currentDirectory)
            Target Version: \(version),
            Previous Version: \(previousReleaseBranch?.version ?? "nil")
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
        buildExecutable.run(targetsToRun: targetsToRun, runPretty: runPretty, projectName: projectName)
        
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
        
        let bitbucketURLString = SetupHelper.bitbucketURL(from: dictionary)
        if shouldRedirectToBitbucket,
            let url = URL(string: bitbucketURLString ?? "") {
            
            Console.writeMessage("**Opening bitbucket PR creation...")
            let controller = BitbucketController(baseURL: url)
            
            do {
                try controller.redirectToBitbucket(sourceBranch: teamMergeBranch.path, targetBranch: releaseBranch.path)
            } catch {
                Console.writeMessage(error)
            }
        }
        
        // MARK: Notify slack for PR
        
        Console.writeMessage("**Notifing Slack...")
        
        if let bitbucketURL = URL(string: bitbucketURLString ?? "") {
            
            let parameters = BitbucketController.parameters(for: teamMergeBranch.path, targetBranch: releaseBranch.path)
            
            slackController.postPRMessage(bitbucketBaseURL: bitbucketURL, bitbucketParameters: parameters) { result in
                
                switch result {
                case .success:
                    Console.writeMessage("Successfully notified slack! \n", styled: .blue)
                case .failure(let error):
                    Console.writeWarning(error)
                }
            }
        }
        
        runner.wait()
        
        // MARK: - Post-PR
        let postPRExecutable = PostPRExecutable()
        postPRExecutable.run(developBranchesToRun: developBranchesToRun, releaseBranch: releaseBranch)
        
        slackController.postFinishedTeamMergeMessage { result in
            
            switch result {
            case .success:
                Console.writeMessage("Successfully notified slack! \n", styled: .blue)
            case .failure(let error):
                Console.writeWarning(error)
            }
        }
        
        // MARK: - Jenkins
        if shouldRunJenkins {
            let jenkinsExecutable = JenkinsExecutable(slackController: slackController)
            jenkinsExecutable.run(with: dictionary, version: version, shouldRequestInput: shouldRequestInput)
        }
    }
}
