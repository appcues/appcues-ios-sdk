//
//  SdkMetrics.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/18/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal struct SdkMetrics {

    private static let syncQueue = DispatchQueue(label: "appcues-sdk-metrics")

    // Protected by syncQueue
    nonisolated(unsafe) private static var metrics: [UUID: SdkMetrics] = [:]

    // the time when the tracking was first captured by the SDK - the call to `track(event)` for instance
    private var trackedAt: Date?

    // the time when the tracking request was sent out in an API call to check for qualification
    private var requestedAt: Date?

    // the time when the network response was received
    private var respondedAt: Date?

    // the time when the UI presentation began
    private var renderStartAt: Date?

    static func clear() {
        syncQueue.async {
            metrics.removeAll()
        }
    }

    static func tracked(_ id: UUID, time: Date?) {
        // only if a tracking time is known, allow creation of a new record
        // other network calls not related to a captured tracking time, like batched background analytics
        // or requests to get an experience by ID, are not tracked
        guard let time = time else { return }
        syncQueue.async {
            metrics[id, default: SdkMetrics()].trackedAt = time
        }
    }

    static func requested(_ id: UUID?, time: Date = Date()) {
        guard let id = id else { return }
        // only capture if record is already created -- a known analytics tracking time
        syncQueue.async {
            metrics[id]?.requestedAt = time
        }
    }

    static func responded(_ id: UUID?, time: Date = Date()) {
        guard let id = id else { return }
        // only capture if record is already created -- a known analytics tracking time
        syncQueue.async {
            metrics[id]?.respondedAt = time
        }
    }

    static func renderStart(_ id: UUID?, time: Date = Date()) {
        guard let id = id else { return }
        // only capture if record is already created -- a known analytics tracking time
        syncQueue.async {
            metrics[id]?.renderStartAt = time
        }
    }

    static func remove(_ id: UUID) {
        syncQueue.async {
            _ = metrics.removeValue(forKey: id)
        }
    }

    static func trackRender(_ id: UUID?) -> [String: Any] {
        guard let id = id,
              let timings: SdkMetrics = syncQueue.sync(execute: { metrics[id] }),
              let trackedAt = timings.trackedAt,
              let requestedAt = timings.requestedAt,
              let respondedAt = timings.respondedAt,
              let renderStartAt = timings.renderStartAt else {
            return [:]
        }

        let renderedAt = Date()

        let timeBeforeRequest = Int(requestedAt.millisecondsSince1970 - trackedAt.millisecondsSince1970)
        let timeNetwork = Int(respondedAt.millisecondsSince1970 - requestedAt.millisecondsSince1970)
        let timeProcessingResponse = Int(renderStartAt.millisecondsSince1970 - respondedAt.millisecondsSince1970)
        let timePresenting = Int(renderedAt.millisecondsSince1970 - renderStartAt.millisecondsSince1970)
        let timeTotal = Int(renderedAt.millisecondsSince1970 - trackedAt.millisecondsSince1970)

        // remove this item now that we've tracked it
        remove(id)

        return [
            "_sdkMetrics": [
                "timeBeforeRequest": timeBeforeRequest,
                "timeNetwork": timeNetwork,
                "timeProcessingResponse": timeProcessingResponse,
                "timePresenting": timePresenting,
                "timeTotal": timeTotal
            ]
        ]

    }
}
