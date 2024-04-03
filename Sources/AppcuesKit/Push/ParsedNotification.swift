//
//  ParsedNotification.swift
//  AppcuesKit
//
//  Created by Matt on 2024-03-05.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation

internal struct ParsedNotification {
    let accountID: String
    let applicationID: String
    let userID: String
    let notificationID: String
    let workflowID: String?
    let workflowTaskID: String?
    let deepLinkURL: URL?
    let experienceID: String?
    let attachmentURL: URL?
    let isTest: Bool
    let isInternal: Bool

    init?(userInfo: [AnyHashable: Any]) {
        guard let accountID = userInfo["appcues_account_id"] as? String,
              let applicationID = userInfo["appcues_app_id"] as? String,
              let userID = userInfo["appcues_user_id"] as? String,
              let notificationID = userInfo["appcues_notification_id"] as? String else {
            return nil
        }

        self.accountID = accountID
        self.applicationID = applicationID
        self.userID = userID
        self.notificationID = notificationID

        self.workflowID = userInfo["appcues_workflow_id"] as? String
        self.workflowTaskID = userInfo["appcues_workflow_task_id"] as? String
        self.deepLinkURL = (userInfo["appcues_deep_link_url"] as? String)
            .flatMap { URL(string: $0) }
        self.experienceID = userInfo["appcues_experience_id"] as? String
        self.attachmentURL = (userInfo["appcues_attachment_url"] as? String)
            .flatMap { URL(string: $0) }
        self.isTest = userInfo["appcues_test"] != nil
        self.isInternal = userInfo["_appcues_internal"] as? Bool ?? false
    }
}
