//
//  AnalyticsPublisher.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsPublishing: AnyObject {
    func publish(_ update: TrackingUpdate)

    func register(subscriber: AnalyticsSubscribing)
    func remove(subscriber: AnalyticsSubscribing)

    func register(decorator: AnalyticsDecorating)
    func remove(decorator: AnalyticsDecorating)
}

internal class AnalyticsPublisher: AnalyticsPublishing {

    private weak var appcues: Appcues?

    private let sessionMonitor: SessionMonitoring

    private var subscribers: [WeakAnalyticsSubscribing] = []
    private var decorators: [WeakAnalyticsDecorating] = []

    init(container: DIContainer) {
        self.appcues = container.owner
        self.sessionMonitor = container.resolve(SessionMonitoring.self)
    }

    func register(subscriber: AnalyticsSubscribing) {
        subscribers.append(WeakAnalyticsSubscribing(subscriber))
    }

    func remove(subscriber: AnalyticsSubscribing) {
        subscribers.removeAll { $0.value === subscriber }
    }

    func register(decorator: AnalyticsDecorating) {
        decorators.append(WeakAnalyticsDecorating(decorator))
    }

    func remove(decorator: AnalyticsDecorating) {
        decorators.removeAll { $0.value === decorator }
    }

    func publish(_ update: TrackingUpdate) {
        let isSessionActive = appcues?.isActive ?? false

        if !isSessionActive || sessionMonitor.isSessionExpired {
            if sessionMonitor.start() {
                // immediately track session started before any subsequent analytics
                decorateAndPublish(
                    TrackingUpdate(
                        type: .event(name: Events.Session.sessionStarted.rawValue, interactive: true),
                        properties: nil,
                        isInternal: true
                    )
                )
            } else {
                // no session could be started (no user) and we cannot
                // track anything
                return
            }
        } else {
            // we have a valid session, update its last activity timestamp to push out the timeout
            sessionMonitor.updateLastActivity()
        }

        decorateAndPublish(update)
    }

    private func decorateAndPublish(_ update: TrackingUpdate) {
        var update = update

        // Apply decorations, removing any decorators that have been released from memory.
        decorators.removeAll {
            update = $0.value?.decorate(update) ?? update
            return $0.value == nil
        }

        // Call subscribers, removing any subscribers that have been released from memory.
        subscribers.removeAll {
            $0.value?.track(update: update)
            return $0.value == nil
        }
    }
}

private extension AnalyticsPublisher {
    class WeakAnalyticsSubscribing {
        weak var value: AnalyticsSubscribing?

        init (_ wrapping: AnalyticsSubscribing) { self.value = wrapping }
    }

    class WeakAnalyticsDecorating {
        weak var value: AnalyticsDecorating?

        init (_ wrapping: AnalyticsDecorating) { self.value = wrapping }
    }
}

extension AnalyticsPublishing {
    func screen(title: String) {
        publish(TrackingUpdate(type: .screen(title), isInternal: true))
    }
}
