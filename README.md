# Swifty Scripts

A tool made in swift I use to help automate some processes. Originally was built to help automate the merging of different branches and deploying process for PW. But now will be made general for different use cases like automatic branch deletion.

***
## Description ##
USAGE: swiftyscripts [command] <options>

COMMANDS:
* -v: Shows the current version 
* -help: Shows list of arguments and executables 
* merge: Does a team merge 
* build: Build all the targets listed in the `TargetsToRun` config 
* jenkins: Triggers a Jenkins build for every Jenkins.schemes listed 
* post-only: Only executes the post-PR portion of the team merge 

## Getting Started ##
* Clone this project
* `cd` into project directory
* Run Command `swift build`
* Run Command `swift package generate-xcodeproj`
* Open Xcode Project

## To Run ##
* `cd` to the target project folder if you don't want to specify -dir. Make sure you have a config setup in the project. See swiftyscripts/config/config.plist for example config.
* You can run the project in xcode for debugging
	* In order to specify an argument go to edit Scheme -> Arguments
        * You may need to specify PATH in environment variables
* You can run the binary in the Products folder to run live on terminal. **NOTE** This binary cannot run independently without being in the same folder as the packages
* You can also run via terminal
	* `cd` into project directory
	* Run `swift build`
	* Run `.build/debug/{INSERT PROJECT NAME HERE}` with arguments (e.g. .build/debug/SwiftyScripts -v 3.10 -pv 3.9)
	* -v or version is required
	* Note: this binary can run independently of the package dependencies 
* If you want to run binary locally with custom `SwiftyScripts` bash
	* Run `export PATH=path_to_binary_folder:”${PATH}”`
	* E.g. `export PATH=/Users/kchen/Documents/Xcode\ Play/TeamMergeAutomation/.build/x86_64-apple-macosx10.10/debug:"${PATH}"`
	* This will allow you to do “SwiftyScripts start -v 3.9” for the running terminal session. However to do it system wide and on every terminal you need to change .bash_profile and add the `export...` to the file
	
## To Unit Test ##
* If using xcode, go to Edit Scheme -> Test -> Plus button on bottom -> Add "Source Tests"

## To Deploy ##
* `cd` to project directory
* Use jenkins to run jenkins file. This will tar ball the binary.
* Now you need to modify the brew formula
	* In TM-homebrew-tap repo, open swiftyscripts.rb
	* Modify the url to the new swiftyscripts.tar.gz link in jenkins.
	* Modify the sha256. Copy the sha output in jenkins
	* Modify the version
	* Save and push changes
* If you have not installed swiftyscripts yet then first run `brew tap kchen/tm-homebrew-private git@bitbucket.org:kevcodex/tm-homebrew-tap.git` to open this tap
* Then run `brew install swiftyscripts` to install swiftyscripts
* If you have already installed swiftyscripts then run `brew upgrade swiftyscripts` to update swiftyscripts. Note you may have to run `brew update` first.
* Now you can freely run swiftyscripts commands like `swiftyscripts -v 3.9`
* TODO: Find a simpler way to deploy if possible

