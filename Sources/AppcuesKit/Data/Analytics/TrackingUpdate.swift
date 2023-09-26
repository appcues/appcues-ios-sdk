//
//  TrackingUpdate.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct TrackingUpdate {

    enum TrackingType: Equatable {
        case event(name: String, interactive: Bool)
        case screen(String)
        case profile(interactive: Bool)
        case group(String?)
    }

    enum Policy {
        // any tracking activity in the queue should be immediately flushed before this one
        // then send this one immediately (i.e. user or group updates)
        case flushThenSend

        // this activity can be appended to any tracking activity in the queue, but all should
        // then be flushed immediately, since this update can affect flow qualification
        case queueThenFlush

        // this is background tracking data (i.e. flow analytics) and it can be queued and
        // sent at a later time, does not affect flow qualification
        case queue
    }

    let type: TrackingType
    var properties: [String: Any]?
    var context: [String: Any]?
    let timestamp = Date()
    let isInternal: Bool

    var policy: Policy {
        switch type {
        case let .event(_, interactive):
            return interactive ? .queueThenFlush : .queue

        case .screen:
            return .queueThenFlush

        case let .profile(interactive):
            // a profile update would only be non-interactive if it was not affecting the
            // user login status at all, just updating some attributes that can be batched
            // with the next event. If a new profile update comes in prior to this, the queued
            return interactive ? .flushThenSend : .queue

        case .group:
            return .flushThenSend
        }
    }
}
