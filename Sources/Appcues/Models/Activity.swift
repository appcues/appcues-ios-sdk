//
//  Activity.swift
//  Appcues
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API request body for registering user activity.
internal struct Activity: Encodable {
    let requestID = UUID()
    let events: [Event]?
    let profileUpdate: [String: String]?

    internal init(events: [Event]?, profileUpdate: [String: String]? = nil) {
        self.events = events
        self.profileUpdate = profileUpdate
    }
}
