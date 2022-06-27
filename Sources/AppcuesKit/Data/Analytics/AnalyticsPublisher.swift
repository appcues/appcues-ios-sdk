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

    private var subscribers: [WeakAnalyticsSubscribing] = []
    private var decorators: [WeakAnalyticsDecorating] = []

    init(container: DIContainer) {
        self.appcues = container.owner
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
        guard appcues?.isActive ?? false else { return }

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
    // helper used for internal SDK events to allow for enum cases to be passed for the event name
    func track<T>(_ item: T, properties: [String: Any]?, interactive: Bool) where T: RawRepresentable, T.RawValue == String {
        publish(TrackingUpdate(type: .event(name: item.rawValue, interactive: interactive),
                               properties: properties,
                               isInternal: true))
    }

    func screen(title: String) {
        publish(TrackingUpdate(type: .screen(title), isInternal: true))
    }
}
