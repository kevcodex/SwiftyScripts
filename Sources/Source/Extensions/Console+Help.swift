//
//  Console+Help.swift
//
//  Created by Kirby on 11/19/17.
//

import ScriptHelpers

extension Console {
    // TODO: Modify so the Argument prints out the info
    static func showHelp() {
        Console.writeMessage(
            """
            OVERVIEW: To help automate our team merge process

            USAGE: swiftyscripts [command] <options>

            COMMANDS:
                start           Runs the team merge operation with options. At a minimum you need to specify the version to run. E.g. swiftyscripts start -v 3.11
            
            OPTIONS:
                -v <value>      **REQUIRED** The version to perform the team merge on
                -pv <value>     The previous version to pull from if any.
                -dir <path>     Set the path of the project directory. By default the path is the current working directory. This directory must contain a swiftyscripts/config/config.plist
                -help           Display available options.
                -jenkins-off     Will not run the jenkins deployment script. NOTE: You cannot have this flag off and -jenkinsonly on.
                -post-only      Run only the post PR section of the script
                -jenkins-only   Runs only the jenkins build starter
                -no-input       Run script without any user input
                -pretty         Run building in xcpretty format. Script will bail if xcpretty is not installed
                -no-bitbucket   Does not redirect user to bitbucket PR creation
                -u <value>      The user that is executing this script. E.g. kchen@phunware.com

            PLIST CONFIG:
                - Here is a list of all required and optional parameters. Unless specified the param is required. See Config in the project for an example.
            
                Jenkins (Required if you want to run jenkins)
                    - credentials
                        - email
                        - apiToken (Get from Jenkins)
                    - delayBetweenBuilds
                    - label
                        - prefix (The project name)
                        - numberOfConfigurations (The number of configurations that will deploy e.g. qa, uat, prod = 3)
                    - schemes (Array of each build scheme)
                        - Each item
                            - target
                            - startBuildNumber (String, Optional, will override build number that is determined from jenkins)
                            - configuration (String, Optional, the CONFIGURATION param in jenkins)
                            - xcodeVersion (String, Optional, the XCODE_VERSION param in jenkins)
                            - shouldDeploy (Bool, Optional, the DEPLOY param in jenkins)
                            - shouldDistribute (Bool, Optional, the DISTRIBUTE param in jenkins)
                            - shouldReleaseDSYMS (Bool, Optional, the DSYMS param in jenkins)
                            - shouldReduceBuilds (Bool, Optional, the REDUCE_BUILDS param in jenkins)
                            - shouldNotifySlack (Bool, Optional, the NOTIFY_SLACK param in jenkins)
                            - isSubmissionCandidate (Bool, Optional, the SUBMISSION_CANDIDATE param in jenkins)
                            - knownIssues (String, Optional, the KNOWN_ISSUES param in jenkins)

                TargetsToRun (Array of each target in string)
                    - Each item (String)

                BranchesToRun (Array of each branch)
                    - Each item (String)
            """
        )
    }
}
