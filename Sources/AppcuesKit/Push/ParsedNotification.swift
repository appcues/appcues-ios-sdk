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
    let userID: String
    let notificationID: String
    let workflowID: String
    let workflowTaskID: String
    let transactionID: String
    let deepLinkURL: URL?
    let experienceID: String?
    let attachmentURL: URL?
    let attachmentType: String?
    let isTest: Bool

    init?(userInfo: [AnyHashable: Any]) {
        guard let accountID = userInfo["appcues_account_id"] as? String,
        let userID = userInfo["appcues_user_id"] as? String,
        let notificationID = userInfo["appcues_notification_id"] as? String,
        let workflowID = userInfo["appcues_workflow_id"] as? String,
        let workflowTaskID = userInfo["appcues_workflow_task_id"] as? String,
        let transactionID = userInfo["appcues_transaction_id"] as? String else {
            return nil
        }

        self.accountID = accountID
        self.userID = userID
        self.notificationID = notificationID
        self.workflowID = workflowID
        self.workflowTaskID = workflowTaskID
        self.transactionID = transactionID

        self.deepLinkURL = (userInfo["appcues_deep_link_url"] as? String)
            .flatMap { URL(string: $0) }
        self.experienceID = userInfo["appcues_experience_id"] as? String
        self.attachmentURL = (userInfo["appcues_attachment_url"] as? String)
            .flatMap { URL(string: $0) }
        self.attachmentType = userInfo["appcues_attachment_type"] as? String
        self.isTest = userInfo["appcues_test"] as? Bool ?? false
    }
}
