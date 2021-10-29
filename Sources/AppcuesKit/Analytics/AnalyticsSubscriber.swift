//
//  AnalyticsSubscriber.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsSubscriber {
    func track(update: TrackingUpdate)
}

extension AnalyticsSubscriber {
    func registerForAnalyticsUpdates(_ container: DIContainer) {
        container.resolve(AnalyticsPublisher.self).register(subscriber: self)
    }
}
