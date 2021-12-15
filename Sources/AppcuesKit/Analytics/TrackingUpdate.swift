//
//  TrackingUpdate.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct TrackingUpdate {

    enum TrackingType {
        case event(String)
        case screen(String)
        case profile
        case group
    }

    enum Policy {
        // any tracking activity in the queue should be immediately flushed before this one
        // then send this one immediately (i.e. user or group updates)
        case flushThenSend

        // this activity can be appeneded to any tracking activity in the queue, but all should
        // then be flushed immediately, since this update can affect flow qualification
        case queueThenFlush

        // this is background tracking data (i.e. flow analytics) and it can be queued and
        // sent at a later time, does not affect flow qualificiation
        case queue
    }

    let type: TrackingType
    let policy: Policy
    var properties: [String: Any]?
    let timestamp = Date()
}

extension TrackingUpdate: CustomStringConvertible {
    var description: String {
        return "TODO: translate for logging / debugger"
    }
}
