//
//  ExperienceLifecycleEvent.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal enum ExperienceLifecycleEvent {
    case stepSeen(Experience, Int)
    case stepCompleted(Experience, Int)
    case stepError(Experience, Int, ErrorBody)

    case experienceStarted(Experience)
    case experienceCompleted(Experience)
    case experienceDismissed(Experience, Int)
    case experienceError(Experience, ErrorBody)

    var name: String {
        switch self {
        case .stepSeen:
            return "appcues:v2:step_seen"
        case .stepCompleted:
            return "appcues:v2:step_completed"
        case .stepError:
            return "appcues:v2:step_error"
        case .experienceStarted:
            return "appcues:v2:experience_started"
        case .experienceCompleted:
            return "appcues:v2:experience_completed"
        case .experienceDismissed:
            return "appcues:v2:experience_dismissed"
        case .experienceError:
            return "appcues:v2:experience_error"
        }
    }

    private var experience: Experience {
        switch self {
        case .stepSeen(let experience, _),
                .stepCompleted(let experience, _),
                .stepError(let experience, _, _),
                .experienceStarted(let experience),
                .experienceCompleted(let experience),
                .experienceDismissed(let experience, _),
                .experienceError(let experience, _):
            return experience
        }
    }

    var error: ErrorBody? {
        switch self {
        case let .stepError(_, _, error), let .experienceError(_, error):
            return error
        default: return nil
        }
    }

    var properties: [String: Any] {
        let experience = self.experience

        var properties: [String: Any] = [
            "experienceId": experience.id.uuidString.lowercased(),
            "experienceName": experience.name
            // TODO: The experience object does not current include version
//            "version": experience.version
            // TODO: Add locale values to analytics for localized experiences
//            "localeName": "",
//            "localeId": ""
        ]

        switch self {
        case .stepSeen(_, let index),
                .stepCompleted(_, let index),
                .stepError(_, let index, _),
                .experienceDismissed(_, let index):
            if experience.steps.indices.contains(index) {
                let step = experience.steps[index]
                properties["stepId"] = step.id.uuidString.lowercased()
                properties["stepNumber"] = index
            }
        case .experienceStarted, .experienceCompleted, .experienceError:
            break
        }

        if let error = error {
            properties["message"] = error.message
            properties["errorId"] = error.id
        }

        return properties
    }
}

extension ExperienceLifecycleEvent {
    struct ErrorBody: ExpressibleByStringInterpolation {
        let message: String
        let id: UUID

        init(message: String, id: UUID = UUID()) {
            self.message = message
            self.id = id
        }

        // Conveniently init with `"message"` or `"\(messageVar)"` instead of `ExperienceLifecycleEvent.Error(message: messageVar)`.
        init(stringLiteral value: String) {
            message = value
            id = UUID()
        }
    }
}
