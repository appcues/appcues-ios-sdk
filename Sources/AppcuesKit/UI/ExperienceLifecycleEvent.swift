//
//  ExperienceLifecycleEvent.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal enum ExperienceLifecycleEvent {
    case stepAttempted(Experience, Int)
    case stepStarted(Experience, Int)
    case stepInteracted(Experience, Int)
    case stepCompleted(Experience, Int)
    case stepSkipped(Experience, Int)
    case stepError(Experience, Int, String)
    case stepAborted(Experience, Int)

    case flowAttempted(Experience)
    case flowStarted(Experience)
    case flowCompleted(Experience)
    case flowSkipped(Experience)
    case flowError(Experience, String)
    case flowAborted(Experience)

    var name: String {
        switch self {
        case .stepAttempted:
            return "appcues:step_attempted"
        case .stepStarted:
            return "appcues:step_started"
        case .stepInteracted:
            return "appcues:step_interacted"
        case .stepCompleted:
            return "appcues:step_completed"
        case .stepSkipped:
            return "appcues:step_skipped"
        case .stepError:
            return "appcues:step_error"
        case .stepAborted:
            return "appcues:step_aborted"
        case .flowAttempted:
            return "appcues:flow_attempted"
        case .flowStarted:
            return "appcues:flow_started"
        case .flowCompleted:
            return "appcues:flow_completed"
        case .flowSkipped:
            return "appcues:flow_skipped"
        case .flowError:
            return "appcues:flow_error"
        case .flowAborted:
            return "appcues:flow_aborted"
        }
    }

    private var experience: Experience {
        switch self {
        case .stepAttempted(let experience, _),
                .stepStarted(let experience, _),
                .stepInteracted(let experience, _),
                .stepCompleted(let experience, _),
                .stepSkipped(let experience, _),
                .stepError(let experience, _, _),
                .stepAborted(let experience, _):
            return experience
        case .flowAttempted(let experience),
                .flowStarted(let experience),
                .flowCompleted(let experience),
                .flowSkipped(let experience),
                .flowError(let experience, _),
                .flowAborted(let experience):
            return experience
        }
    }

    var message: String? {
        switch self {
        case let .stepError(_, _, message), let .flowError(_, message):
            return message
        default: return nil
        }
    }

    var properties: [String: Any] {
        let experience = self.experience

        var properties: [String: Any] = [
            "flowId": experience.id.uuidString.lowercased(),
            "flowName": experience.name,
            "flowType": "journey"
        ]

        switch self {
        case .stepAttempted(_, let index),
                .stepStarted(_, let index),
                .stepInteracted(_, let index),
                .stepCompleted(_, let index),
                .stepSkipped(_, let index),
                .stepError(_, let index, _),
                .stepAborted(_, let index):
            if experience.steps.indices.contains(index) {
                let step = experience.steps[index]
                properties["stepId"] = step.id.uuidString.lowercased()
                properties["stepType"] = "modal"
                properties["stepNumber"] = index
            }
        case .flowAttempted, .flowStarted, .flowCompleted, .flowSkipped, .flowError, .flowAborted:
            break
        }

        if let message = message {
            properties["error"] = message
            properties["detail"] = message
        }

        return properties
    }
}
