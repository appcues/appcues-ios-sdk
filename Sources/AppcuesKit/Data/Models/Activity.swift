//
//  Activity.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import os.log

/// API request body for registering user activity.
internal struct Activity {
    let logger: Logging

    let requestID = UUID()
    var events: [Event]?
    var profileUpdate: [String: Any]?
    let userID: String
    let accountID: String
    let groupID: String?
    let groupUpdate: [String: Any]?
    let userSignature: String?
    let sessionID: String

    internal init(
        accountID: String,
        sessionID: String,
        userID: String,
        events: [Event]?,
        profileUpdate: [String: Any]? = nil,
        groupID: String? = nil,
        groupUpdate: [String: Any]? = nil,
        userSignature: String? = nil,
        logger: Logging = OSLog.disabled
    ) {
        self.accountID = accountID
        self.sessionID = sessionID
        self.userID = userID
        self.events = events
        self.profileUpdate = profileUpdate
        self.groupID = groupID
        self.groupUpdate = groupUpdate
        self.userSignature = userSignature
        self.logger = logger
    }
}

extension Activity: Encodable {
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case events
        case profileUpdate = "profile_update"
        case userID = "user_id"
        case accountID = "account_id"
        case sessionID = "session_id"
        case groupID = "group_id"
        case groupUpdate = "group_update"
        // note: userSignature is not serialized - used on request Authentication header when present
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountID, forKey: .accountID)
        try container.encode(sessionID, forKey: .sessionID)
        try container.encode(userID, forKey: .userID)
        try container.encode(groupID, forKey: .groupID)
        try container.encode(requestID.appcuesFormatted, forKey: .requestID)
        if let events = events {
            try container.encode(events, forKey: .events)
        }

        if let profileUpdate = profileUpdate {
            var profileInfoContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .profileUpdate)
            try profileInfoContainer.encodeSkippingInvalid(profileUpdate, logger: logger)
        }

        if let groupUpdate = groupUpdate {
            var groupInfoContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .groupUpdate)
            try groupInfoContainer.encodeSkippingInvalid(groupUpdate, logger: logger)
        }
    }
}
