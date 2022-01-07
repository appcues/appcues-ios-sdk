//
//  AnalyticsSubscribing.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsSubscribing: AnyObject {
    func track(update: TrackingUpdate)
}

extension AnalyticsSubscribing {
    func registerForAnalyticsUpdates(_ container: DIContainer) {
        container.resolve(AnalyticsPublishing.self).register(subscriber: self)
    }
}
