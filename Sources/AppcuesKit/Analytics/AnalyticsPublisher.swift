//
//  AnalyticsPublisher.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsPublisher: AnyObject {
    func track(name: String, properties: [String: Any]?, sync: Bool)
    func screen(title: String, properties: [String: Any]?, sync: Bool)

    func register(subscriber: AnalyticsSubscriber)
    func remove(subscriber: AnalyticsSubscriber)

    func register(decorator: TrackingDecorator)
    func remove(decorator: TrackingDecorator)
}

extension AnalyticsPublisher {
    // helper used for internal SDK events to allow for enum cases to be passed for the event name
    func track<T>(_ item: T, properties: [String: Any]? = nil, sync: Bool = false) where T: RawRepresentable, T.RawValue == String {
        track(name: item.rawValue, properties: properties, sync: sync)
    }
}
