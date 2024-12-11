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
    func log(_ update: TrackingUpdate)

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
                let sessionUpdate = TrackingUpdate(
                    type: .event(name: Events.Session.sessionStarted.rawValue, interactive: true),
                    properties: nil,
                    isInternal: true
                )
                notifySubscribers(decorate(sessionUpdate))
            } else {
                // no session could be started (no user) and we cannot
                // track anything
                return
            }
        } else {
            // we have a valid session, update its last activity timestamp to push out the timeout
            sessionMonitor.updateLastActivity()
        }

        notifySubscribers(decorate(update))
    }

    func log(_ update: TrackingUpdate) {
        guard let logger = appcues?.config.logger else { return }

        let update = decorate(update)

        let name: String
        switch update.type {
        case let .event(eventName, _):
            name = eventName
        case let .screen(title):
            name = "Screen (\(title))"
        case .profile:
            name = "Profile Update"
        case .group:
            name = "Group Update"
        }

        let event = Event(name: name, attributes: update.properties, context: update.context)

        if let data = try? NetworkClient.encoder.encode(event), let string = String(data: data, encoding: .utf8) {
            logger.debug("UNPUBLISHED ANALYTIC:\n%{private}@", string)
        }
    }

    private func decorate(_ update: TrackingUpdate) -> TrackingUpdate {
        var update = update

        decorators.forEach {
            update = $0.value?.decorate(update) ?? update
        }

        return update
    }

    private func notifySubscribers(_ update: TrackingUpdate) {

        subscribers.forEach {
            $0.value?.track(update: update)
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
    // This is an extension method so that the logic is testable instead of being mocked.
    /// Redirect unpublished updates to the SDK logger.
    func conditionallyPublish(_ update: TrackingUpdate, shouldPublish: Bool) {
        if shouldPublish {
            publish(update)
        } else {
            log(update)
        }
    }

    func screen(title: String) {
        publish(TrackingUpdate(type: .screen(title), isInternal: true))
    }
}
