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
        case event(name: String, sync: Bool)
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
    var properties: [String: Any]?
    let timestamp = Date()

    var policy: Policy {
        switch type {
        case let .event(_, sync):
            return sync ? .queueThenFlush : .queue

        case .screen:
            return .queueThenFlush

        case .group, .profile:
            return .flushThenSend
        }
    }
}

extension TrackingUpdate: CustomStringConvertible {
    var description: String {
        return "TODO: translate for logging / debugger"
    }
}
