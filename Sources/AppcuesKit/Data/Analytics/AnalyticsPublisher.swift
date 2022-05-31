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

    private var subscribers: [AnalyticsSubscribing] = []
    private var decorators: [AnalyticsDecorating] = []

    init(container: DIContainer) {
        self.appcues = container.owner
    }

    func register(subscriber: AnalyticsSubscribing) {
        subscribers.append(subscriber)
    }

    func remove(subscriber: AnalyticsSubscribing) {
        subscribers.removeAll { $0 === subscriber }
    }

    func register(decorator: AnalyticsDecorating) {
        decorators.append(decorator)
    }

    func remove(decorator: AnalyticsDecorating) {
        decorators.removeAll { $0 === decorator }
    }

    func publish(_ update: TrackingUpdate) {
        guard appcues?.isActive ?? false else { return }

        var update = update

        for decorator in decorators {
            update = decorator.decorate(update)
        }

        for subscriber in subscribers {
            subscriber.track(update: update)
        }
    }
}

extension AnalyticsPublishing {
    // helper used for internal SDK events to allow for enum cases to be passed for the event name
    func track<T>(_ item: T, properties: [String: Any]?, interactive: Bool) where T: RawRepresentable, T.RawValue == String {
        publish(TrackingUpdate(type: .event(name: item.rawValue, interactive: interactive), properties: properties))
    }

    func screen(title: String) {
        publish(TrackingUpdate(type: .screen(title)))
    }
}
