//
//  Activity.swift
//  Appcues
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API request body for registering user activity.
internal struct Activity {
    let requestID = UUID()
    let events: [Event]?
    let profileUpdate: [String: Any]?
    let userID: String
    let accountID: String

    internal init(accountID: String,
                  userID: String,
                  events: [Event]?,
                  profileUpdate: [String: Any]? = nil) {
        self.accountID = accountID
        self.userID = userID
        self.events = events
        self.profileUpdate = profileUpdate
    }
}

extension Activity: Encodable {
    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case events
        case profileUpdate = "profile_update"
        case userID = "user_id"
        case accountID = "account_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountID, forKey: .accountID)
        try container.encode(userID, forKey: .userID)
        try container.encode(requestID, forKey: .requestID)
        if let events = events {
            try container.encode(events, forKey: .events)
        }

        if let profileUpdate = profileUpdate {
            var profileInfoContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .profileUpdate)
            try profileInfoContainer.encodeSkippingInvalid(profileUpdate)
        }
    }
}
