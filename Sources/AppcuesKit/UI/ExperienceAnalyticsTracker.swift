//
//  ExperienceAnalyticsTracker.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/24/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal class ExperienceAnalyticsTracker: ExperienceEventDelegate {

    private let analyticsPublisher: AnalyticsPublishing

    init(container: DIContainer) {
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
    }

    func lifecycleEvent(_ event: ExperienceLifecycleEvent) {

        analyticsPublisher.track(name: event.name, properties: event.properties, sync: false)
    }
}
