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
    case stepInteraction(Experience, Int)
    case stepCompleted(Experience, Int)
    case stepError(Experience, Int, String)

    case experienceStarted(Experience)
    case experienceCompleted(Experience)
    case experienceDismissed(Experience, Int)
    case experienceError(Experience, String)

    var name: String {
        switch self {
        case .stepSeen:
            return "appcues:v2:step_seen"
        case .stepInteraction:
            return "appcues:v2:step_interaction"
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
                .stepInteraction(let experience, _),
                .stepCompleted(let experience, _),
                .stepError(let experience, _, _):
            return experience
        case .experienceStarted(let experience),
                .experienceCompleted(let experience),
                .experienceDismissed(let experience, _),
                .experienceError(let experience, _):
            return experience
        }
    }

    var message: String? {
        switch self {
        case let .stepError(_, _, message), let .experienceError(_, message):
            return message
        default: return nil
        }
    }

    var properties: [String: Any] {
        let experience = self.experience

        var properties: [String: Any] = [
            "experienceId": experience.id.uuidString.lowercased(),
            "experienceName": experience.name
        ]

        switch self {
        case .stepSeen(_, let index),
                .stepInteraction(_, let index),
                .stepCompleted(_, let index),
                .stepError(_, let index, _),
                .experienceDismissed(_, let index):
            if experience.steps.indices.contains(index) {
                let step = experience.steps[index]
                properties["stepId"] = step.id.uuidString.lowercased()
            }
        case .experienceStarted, .experienceCompleted, .experienceError:
            break
        }

        if let message = message {
            properties["message"] = message
        }

        return properties
    }
}
