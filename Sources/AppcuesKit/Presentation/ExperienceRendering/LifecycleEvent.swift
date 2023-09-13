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
    case experienceRecovered = "appcues:v2:experience_recovered"

    private init?(trackingType: TrackingUpdate.TrackingType) {
        if case .event(let name, _) = trackingType, let val = Self(rawValue: name) {
            self = val
        } else {
            return nil
        }
    }

    /// Map experience model to a general property dictionary.
    @available(iOS 13.0, *)
    static func properties(
        _ experience: ExperienceData,
        _ stepIndex: Experience.StepIndex? = nil,
        error: ErrorBody? = nil
    ) -> [String: Any] {
        var properties: [String: Any] = [
            "experienceId": experience.id.appcuesFormatted,
            "experienceName": experience.name,
            "experienceType": experience.type,
            "experienceInstanceId": experience.instanceID.appcuesFormatted
            // TODO: Add locale values to analytics for localized experiences
//            "localeName": "",
//            "localeId": ""
        ]

        // frameID is added primarily for use by the debugger
        if case let .embed(frameID) = experience.renderContext {
            properties["frameID"] = frameID
        }

        if let version = experience.publishedAt {
            properties["version"] = version
        }

        if let stepIndex = stepIndex, let step = experience.step(at: stepIndex) {
            properties["stepId"] = step.id.appcuesFormatted
            properties["stepType"] = step.type
            // stepIndex is added primarily for use by the debugger
            properties["stepIndex"] = stepIndex.description
        }

        if let error = error {
            properties["message"] = error.message
            properties["errorId"] = error.id.appcuesFormatted
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
        let message: String?
        let id: UUID

        init(message: String?, id: UUID = UUID.create()) {
            self.message = message
            self.id = id
        }

        // Conveniently init with `"message"` or `"\(messageVar)"` instead of `ExperienceLifecycleEvent.Error(message: messageVar)`.
        init(stringLiteral value: String) {
            message = value
            id = UUID.create()
        }
    }

    struct EventProperties: Equatable {
        let type: LifecycleEvent
        let experienceID: UUID
        let experienceName: String
        let experienceInstanceID: UUID
        let frameID: String?
        let stepID: UUID?
        let stepIndex: Experience.StepIndex?

        let errorID: UUID?
        let message: String?

        init?(update: TrackingUpdate) {
            guard let type = LifecycleEvent(trackingType: update.type) else { return nil }

            guard let experienceID = UUID(uuidString: update.properties?["experienceId"] as? String ?? ""),
                  let experienceName = update.properties?["experienceName"] as? String,
                  let experienceInstanceID = UUID(uuidString: update.properties?["experienceInstanceId"] as? String ?? "") else {
                return nil
            }

            self.type = type
            self.experienceID = experienceID
            self.experienceName = experienceName
            self.experienceInstanceID = experienceInstanceID
            self.frameID = update.properties?["frameID"] as? String

            self.stepID = UUID(uuidString: update.properties?["stepId"] as? String ?? "")
            self.stepIndex = Experience.StepIndex(description: update.properties?["stepIndex"] as? String ?? "")

            self.errorID = UUID(uuidString: update.properties?["errorId"] as? String ?? "")
            self.message = update.properties?["message"] as? String
        }

        init(
            type: LifecycleEvent,
            experienceID: UUID,
            experienceName: String,
            experienceInstanceID: UUID,
            frameID: String? = nil,
            stepID: UUID? = nil,
            stepIndex: Experience.StepIndex? = nil,
            errorID: UUID? = nil,
            message: String? = nil
        ) {
            self.type = type
            self.experienceID = experienceID
            self.experienceName = experienceName
            self.experienceInstanceID = experienceInstanceID
            self.frameID = frameID
            self.stepID = stepID
            self.stepIndex = stepIndex
            self.errorID = errorID
            self.message = message
        }
    }
}
