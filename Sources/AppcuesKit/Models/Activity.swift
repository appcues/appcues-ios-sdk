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

    internal init(events: [Event]?, profileUpdate: [String: Any]? = nil) {
        self.events = events
        self.profileUpdate = profileUpdate
    }
}

extension Activity: Encodable {
    enum CodingKeys: CodingKey {
        case requestID
        case events
        case profileUpdate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(requestID, forKey: .requestID)
        try container.encode(events, forKey: .events)

        var profileInfoContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .profileUpdate)
        // Swallow any invalid types, but assertionFailure in DEBUG to catch invalid types being passed
        do {
            try profileInfoContainer.encode(profileUpdate)
        } catch EncodingError.invalidValue(_, let context) {
            if case .unsupportedType = (context.underlyingError as? AppcuesEncodingError) {
                assertionFailure(context.debugDescription)
            }
        }
    }
}
