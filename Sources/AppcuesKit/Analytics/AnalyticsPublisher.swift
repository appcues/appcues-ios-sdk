//
//  AnalyticsPublisher.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsPublisher: AnyObject {
    func identify(userID: String, properties: [String: Any]?)
    func track(name: String, properties: [String: Any]?)
    func screen(title: String, properties: [String: Any]?)

    func register(subscriber: AnalyticsSubscriber)
    func remove(subscriber: AnalyticsSubscriber)

    func register(decorator: TrackingDecorator)
    func remove(decorator: TrackingDecorator)
}

extension AnalyticsPublisher {
    func identify(userID: String) {
        identify(userID: userID, properties: nil)
    }

    func track(name: String) {
        track(name: name, properties: nil)
    }

    func screen(title: String) {
        screen(title: title, properties: nil)
    }
}
