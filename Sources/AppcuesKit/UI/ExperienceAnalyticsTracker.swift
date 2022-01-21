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
        // TODO: Studio currently operates off of step-child events, so send those along, but in this temporary manner
        // since eventually appcues:step_child_error, appcues:step_child_activated, and appcues:step_child_deactivated
        // should be unneeded.
        // This assumes the experience JSON step.id is actually the step child ID from studio, and that there's only
        // ever one step per group in the web studio flow.
        switch event {
        case .stepError:
            var properties = event.properties
            properties["stepChildId"] = properties["stepId"]
            properties["stepChildNumber"] = 0
            analyticsPublisher.track(name: "appcues:step_child_error", properties: properties, sync: false)
        case .stepCompleted:
            var properties = event.properties
            properties["stepChildId"] = properties["stepId"]
            properties["stepChildNumber"] = 0
            analyticsPublisher.track(name: "appcues:step_child_deactivated", properties: properties, sync: false)
        default:
            break
        }

        analyticsPublisher.track(name: event.name, properties: event.properties, sync: false)

        switch event {
        case .stepStarted:
            var properties = event.properties
            properties["stepChildId"] = properties["stepId"]
            properties["stepChildNumber"] = 0
            analyticsPublisher.track(name: "appcues:step_child_activated", properties: properties, sync: false)
        default:
            break
        }
    }
}
