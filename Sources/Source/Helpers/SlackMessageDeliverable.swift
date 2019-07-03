//
//  SlackMessageDeliverable.swift
//  
//
//  Created by Kevin Chen on 7/3/19.
//

import Foundation
import ScriptHelpers


protocol SlackMessageDeliverable {
    var slackController: SlackController { get }
}

extension SlackMessageDeliverable {
    
    /// Sets up the slack controller for sending messages
    /// - Parameter dictionary: The config dictionary
    /// - Parameter slackUser: The string of the user email
    /// - Returns: True if successfully setup
    @discardableResult
    func setupSlackController(from dictionary: [String: Any]?, slackUser: String) -> Bool {
        guard let slackInfo = SetupHelper.createSlackInfo(from: dictionary) else {
            return false
        }
        
        slackController.setup(slackUser: slackUser, channel: slackInfo.channel, path: slackInfo.path)
        
        return true
    }
    
    /// Exits the script with a message to console and slack.
    /// Should just be used when script is actually running.
    func exit(_ int: Int32, with message: String) -> Never {
        
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
}
