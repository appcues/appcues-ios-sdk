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
        case flushThenSend(waitForBatch: Bool)

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
        case let .event(name, interactive):
            if name == Events.Session.sessionStarted.rawValue {
                // session_started is a special case, which is allowed to batch with the identify()
                // that often is directly associated with it, and potentially a group()
                return .flushThenSend(waitForBatch: true)
            } else if interactive {
                // this would handle track(event) calls which may qualify content
                return .queueThenFlush
            } else {
                // non-interactive flow events
                return .queue
            }

        case .screen:
            return .queueThenFlush

        case let .profile(interactive):
            // a profile update would only be non-interactive if it was not affecting the
            // user login status at all, just updating some attributes that can be batched
            // with the next event. If a new profile update comes in prior to this, the queued
            // updates will be flushed immediately before processing the new update.
            //
            // an identify sends `waitForBatch: true` so that a 50ms buffer is used to batch
            // any subsequent group() call - to avoid any stale group information in the request
            // body sent to the API for qualification
            return interactive ? .flushThenSend(waitForBatch: true) : .queue

        case .group:
            return .flushThenSend(waitForBatch: false)
        }
    }
}
