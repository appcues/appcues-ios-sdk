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
    func screen(title: String, properties: [String: Any]?)

    func register(subscriber: AnalyticsSubscribing)
    func remove(subscriber: AnalyticsSubscribing)

    func register(decorator: AnalyticsDecorating)
    func remove(decorator: AnalyticsDecorating)
}

extension AnalyticsPublisher {
    // helper used for internal SDK events to allow for enum cases to be passed for the event name
    func track<T>(_ item: T, properties: [String: Any]?, sync: Bool) where T: RawRepresentable, T.RawValue == String {
        track(name: item.rawValue, properties: properties, sync: sync)
    }

    func screen(title: String) {
        screen(title: title, properties: nil)
    }
}
