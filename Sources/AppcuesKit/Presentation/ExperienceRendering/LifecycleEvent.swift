//
//  LifecycleEvent.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal enum LifecycleEvent: String, CaseIterable {
    case stepSeen = "appcues:v2:step_seen"
    case stepInteraction = "appcues:v2:step_interaction"
    case stepCompleted = "appcues:v2:step_completed"
    case stepError = "appcues:v2:step_error"
    case stepRecovered = "appcues:v2:step_recovered"
    case experienceStarted = "appcues:v2:experience_started"
    case experienceCompleted = "appcues:v2:experience_completed"
    case experienceDismissed = "appcues:v2:experience_dismissed"
    case experienceError = "appcues:v2:experience_error"

    private init?(trackingType: TrackingUpdate.TrackingType) {
        if case .event(let name, _) = trackingType, let val = Self(rawValue: name) {
            self = val
        } else {
            return nil
        }
    }

    /// Map experience model to a general property dictionary.
    static func properties(_ experience: Experience, _ stepIndex: Experience.StepIndex? = nil, error: ErrorBody? = nil) -> [String: Any] {
        var properties: [String: Any] = [
            "experienceId": experience.id.uuidString.lowercased(),
            "experienceName": experience.name
            // TODO: The experience object does not current include version
//            "version": experience.version
            // TODO: Add locale values to analytics for localized experiences
//            "localeName": "",
//            "localeId": ""
        ]

        if let stepIndex = stepIndex, let step = experience.step(at: stepIndex) {
            properties["stepId"] = step.id.uuidString.lowercased()
            // stepIndex is added primarily for use by the debugger
            properties["stepIndex"] = stepIndex.description
        }

        if let error = error {
            properties["message"] = error.message
            properties["errorId"] = error.id.uuidString
        }

        return properties
    }

    /// Map a general property dictionary to a strongly typed struct `EventProperties`.
    static func restructure(update: TrackingUpdate) -> EventProperties? {
        EventProperties(update: update)
    }
}

extension LifecycleEvent {

    struct ErrorBody: ExpressibleByStringInterpolation {
        let message: String
        let id: UUID

        init(message: String, id: UUID = UUID.create()) {
            self.message = message
            self.id = id
        }

        // Conveniently init with `"message"` or `"\(messageVar)"` instead of `ExperienceLifecycleEvent.Error(message: messageVar)`.
        init(stringLiteral value: String) {
            message = value
            id = UUID.create()
        }
    }

    struct EventProperties {
        let type: LifecycleEvent
        let experienceID: UUID
        let experienceName: String
        let stepID: UUID?
        let stepIndex: Experience.StepIndex?

        let errorID: UUID?
        let message: String?

        init?(update: TrackingUpdate) {
            guard let type = LifecycleEvent(trackingType: update.type) else { return nil }

            guard let experienceID = UUID(uuidString: update.properties?["experienceId"] as? String ?? ""),
                  let experienceName = update.properties?["experienceName"] as? String else {
                return nil
            }

            self.type = type
            self.experienceID = experienceID
            self.experienceName = experienceName

            self.stepID = UUID(uuidString: update.properties?["stepId"] as? String ?? "")
            self.stepIndex = Experience.StepIndex(description: update.properties?["stepIndex"] as? String ?? "")

            self.errorID = UUID(uuidString: update.properties?["errorId"] as? String ?? "")
            self.message = update.properties?["message"] as? String
        }
    }
}
