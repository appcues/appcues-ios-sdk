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
        ]

        if let localeName = experience.context?.localeName {
            properties["localeName"] = localeName
        }

        if let localeId = experience.context?.localeId {
            properties["localeId"] = localeId
        }

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
}
