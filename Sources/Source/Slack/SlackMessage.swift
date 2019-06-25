//
//  SlackMessage.swift
//  MiniNe
//
//  Created by Kevin Chen on 2/20/19.
//

import Foundation

struct SlackMessage: Codable {
    
    let text: String
    let username: String
    var channel: String?
    let iconURL: URL?
    let iconEmoji: String?
    
    let attachments: [Attachment]?
    
    init(text: String,
         username: String,
         channel: String? = nil,
         iconURL: URL? = nil,
         iconEmoji: String? = nil,
         attachments: [Attachment]? = nil) {
        
        self.text = text
        self.channel = channel
        self.username = username
        self.iconURL = iconURL
        self.iconEmoji = iconEmoji
        self.attachments = attachments
    }
    
    enum CodingKeys: String, CodingKey {
        case text
        case channel
        case username
        case iconURL = "icon_url"
        case iconEmoji = "icon_emoji"
        case attachments
    }
}

// MARK: - Attachment
extension SlackMessage {
    struct Attachment: Codable {
        let color: String
        let fallback: String
        let fields: [Field]

        struct Field: Codable {
            let title: String
            let value: String
            let short: Bool
        }
    }
}

// Defaults
extension SlackMessage {
    static func startedMessage(slackID: String) -> SlackMessage {
        
        let userField = Attachment.Field(title: "Started By", value: slackID, short: false)
        
        let statusField = Attachment.Field(title: "Status", value: "Started", short: false)
        
        let messageField = Attachment.Field(title: "Message", value: "Team merge is running. Prep your PC wallet", short: false)
        
        let attachment = Attachment(color: "#289DF9", fallback: "Team Merge Event", fields: [userField, statusField, messageField])
        
        return SlackMessage(text: "", username: "Jenkins", channel: nil, iconURL: nil, iconEmoji: ":jenkins-party-parrot:", attachments: [attachment])
    }
    
    static func prMessage(slackID: String, urlString: String?) -> SlackMessage {
        
        let userField = Attachment.Field(title: "Started By", value: slackID, short: false)
        
        let statusField = Attachment.Field(title: "Status", value: "PR Ready", short: false)
        
        let messageField = Attachment.Field(title: "Message", value: "Team merge is ready to make a PR. Link: \(urlString ?? "Missing")", short: false)
        
        let attachment = Attachment(color: "#E628F9", fallback: "Team Merge Event", fields: [userField, statusField, messageField])
        
        return SlackMessage(text: "", username: "Jenkins", channel: nil, iconURL: nil, iconEmoji: ":jenkins-party-parrot:", attachments: [attachment])
    }
    
    static func finishedTeamMergeMessage(slackID: String) -> SlackMessage {
        
        let userField = Attachment.Field(title: "Started By", value: slackID, short: false)
        
        let statusField = Attachment.Field(title: "Status", value: "Completed", short: false)
        
        let messageField = Attachment.Field(title: "Message", value: "Team Merge is completed! Give me yo PC lunch money!", short: false)
        
        let attachment = Attachment(color: "#36a64f", fallback: "Team Merge Event", fields: [userField, statusField, messageField])
        
        return SlackMessage(text: "", username: "Jenkins", channel: nil, iconURL: nil, iconEmoji: ":jenkins-party-parrot:", attachments: [attachment])
    }
    
    static func startedJenkinsMessage(slackID: String) -> SlackMessage {
        
        let userField = Attachment.Field(title: "Started By", value: slackID, short: false)
        
        let statusField = Attachment.Field(title: "Status", value: "Starting Jenkins", short: false)
        
        let messageField = Attachment.Field(title: "Message", value: "Starting the deployment on Jenkins. Prep your PC wallet", short: false)
        
        let attachment = Attachment(color: "#289DF9", fallback: "Team Merge Event", fields: [userField, statusField, messageField])
        
        return SlackMessage(text: "", username: "Jenkins", channel: nil, iconURL: nil, iconEmoji: ":jenkins-party-parrot:", attachments: [attachment])
    }
    
    static func finishedJenkinsMessage(slackID: String) -> SlackMessage {
        
        let userField = Attachment.Field(title: "Started By", value: slackID, short: false)
        
        let statusField = Attachment.Field(title: "Status", value: "Finished Jenkins", short: false)
        
        let messageField = Attachment.Field(title: "Message", value: "Finished starting all deployment builds. Give me yo PC dinner money!", short: false)
        
        let attachment = Attachment(color: "#36a64f", fallback: "Team Merge Event", fields: [userField, statusField, messageField])
        
        return SlackMessage(text: "", username: "Jenkins", channel: nil, iconURL: nil, iconEmoji: ":jenkins-party-parrot:", attachments: [attachment])
    }
    
    static func errorMessage(slackID: String, errorMessage: String) -> SlackMessage {
        
        let userField = Attachment.Field(title: "Started By", value: slackID, short: false)
        
        let statusField = Attachment.Field(title: "Status", value: "Failure", short: false)
        
        let messageField = Attachment.Field(title: "Message", value: "Team Merge failed: \(errorMessage)", short: false)
        
        let attachment = Attachment(color: "#F94128", fallback: "Team Merge Event", fields: [userField, statusField, messageField])
        
        return SlackMessage(text: "", username: "Jenkins", channel: nil, iconURL: nil, iconEmoji: ":jenkins-party-parrot:", attachments: [attachment])
    }
}
