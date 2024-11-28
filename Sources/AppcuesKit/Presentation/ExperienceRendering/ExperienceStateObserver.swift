//
//  ExperienceStateObserver.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal protocol ExperienceStateObserver: AnyObject {
    typealias StateResult = Result<ExperienceStateMachine.State, ExperienceStateMachine.ExperienceError>
    func stateChanged(to result: StateResult)
}

extension Result where Success == ExperienceStateMachine.State, Failure == ExperienceStateMachine.ExperienceError {

    /// Check if the result pertains to a specific experience ID.
    func matches(instanceID: UUID?) -> Bool {
        guard let instanceID = instanceID else { return true }

        switch self {
        case .success(.idling):
            return true
        case .success(.failing(let targetState, _)):
            return targetState.currentExperienceData?.instanceID == instanceID
        case let .success(.beginningExperience(experience)),
            let .success(.beginningStep(experience, _, _, _)),
            let .success(.renderingStep(experience, _, _, _)),
            let .success(.endingStep(experience, _, _, _)),
            let .success(.endingExperience(experience, _, _)),
            let .failure(.experienceAlreadyActive(ignoredExperience: experience)),
            let .failure(.step(experience, _, _, _)),
            let .failure(.experience(experience, _)):
            return experience.instanceID == instanceID
        }
    }
}

extension ExperienceStateMachine {
    typealias Callback = (ExperienceStateObserver.StateResult) -> Bool

    class AnalyticsObserver: ExperienceStateObserver {
        private let analyticsPublisher: AnalyticsPublishing
        private let storage: DataStoring

        init(container: DIContainer) {
            self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
            self.storage = container.resolve(DataStoring.self)
        }

        // swiftlint:disable:next function_body_length
        func stateChanged(to result: StateResult) {
            switch result {
            case .success(.idling):
                break
            case .success(.beginningExperience):
                break
            case .success(.beginningStep):
                break
            case let .success(.renderingStep(experience, stepIndex, _, isFirst: true)):
                storage.lastContentShownAt = Date()
                let metrics = SdkMetrics.trackRender(experience.requestID)
                let experienceStartProps = Dictionary(propertiesFrom: experience).merging(metrics)
                track(
                    experienceEvent: .experienceStarted,
                    properties: experienceStartProps,
                    shouldPublish: result.shouldPublish
                )
                // optionally track the recovery from a render error, if it is now rendering
                trackStepRecovery(ifErrorOn: experience, stepIndex: stepIndex)
                track(
                    experienceEvent: .stepSeen,
                    properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex),
                    shouldPublish: result.shouldPublish
                )
            case let .success(.renderingStep(experience, stepIndex, _, isFirst: false)):
                track(
                    experienceEvent: .stepSeen,
                    properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex),
                    shouldPublish: result.shouldPublish
                )
            case let .success(.endingStep(experience, stepIndex, _, markComplete)):
                if markComplete {
                    track(
                        experienceEvent: .stepCompleted,
                        properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex),
                        shouldPublish: result.shouldPublish
                    )
                }
            case let .success(.endingExperience(experience, stepIndex, markComplete)):
                if markComplete {
                    track(
                        experienceEvent: .experienceCompleted,
                        properties: Dictionary(propertiesFrom: experience),
                        shouldPublish: result.shouldPublish
                    )
                } else {
                    track(
                        experienceEvent: .experienceDismissed,
                        properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex),
                        shouldPublish: result.shouldPublish
                    )
                }
            case .success(.failing):
                break
            case let .failure(.experience(experience, message)):
                track(
                    experienceEvent: .experienceError,
                    properties: Dictionary(propertiesFrom: experience, error: "\(message)"),
                    shouldPublish: result.shouldPublish
                )
            case let .failure(.step(experience, stepIndex, message, recoverable)):
                trackStepError(experience: experience, stepIndex: stepIndex, message: message, recoverable: recoverable)
            case .failure(.experienceAlreadyActive):
                break
            }
        }

        private func track(experienceEvent name: Events.Experience, properties: [String: Any], shouldPublish: Bool) {
            analyticsPublisher.conditionallyPublish(TrackingUpdate(
                type: .event(name: name.rawValue, interactive: false),
                properties: properties,
                isInternal: true
            ), shouldPublish: shouldPublish)
        }

        private func trackStepError(experience: ExperienceData, stepIndex: Experience.StepIndex, message: String, recoverable: Bool) {
            // guard against tracking the same step error repeatedly during retry
            // don't need to guard for published, since this function is only called private to this class
            // and the observer is only attached on published flows
            guard experience.recoverableErrorID == nil else { return }

            let errorID = UUID()
            if recoverable {
                experience.recoverableErrorID = errorID
            }
            let errorProperties = Dictionary(
                propertiesFrom: experience,
                stepIndex: stepIndex,
                error: Events.Experience.ErrorBody(message: message, id: errorID)
            )
            track(experienceEvent: .stepError, properties: errorProperties, shouldPublish: experience.published)
        }

        private func trackStepRecovery(ifErrorOn experience: ExperienceData, stepIndex: Experience.StepIndex) {
            // only track a recovery if we had previously captured a render error for this experience
            guard let errorID = experience.recoverableErrorID else { return }

            let errorProperties = Dictionary(
                propertiesFrom: experience,
                stepIndex: stepIndex,
                error: Events.Experience.ErrorBody(message: nil, id: errorID)
            )
            track(experienceEvent: .stepRecovered, properties: errorProperties, shouldPublish: experience.published)
            experience.recoverableErrorID = nil
        }

        func trackRecoverableError(experience: ExperienceData, message: String) {
            guard experience.published, experience.recoverableErrorID == nil else { return }

            let errorID = UUID()
            experience.recoverableErrorID = errorID
            let errorProperties = Dictionary(
                propertiesFrom: experience,
                error: Events.Experience.ErrorBody(message: message, id: errorID)
            )
            track(experienceEvent: .experienceError, properties: errorProperties, shouldPublish: experience.published)
        }

        func trackErrorRecovery(ifErrorOn experience: ExperienceData) {
            guard experience.published, let errorID = experience.recoverableErrorID else { return }

            let errorProperties = Dictionary(
                propertiesFrom: experience,
                error: Events.Experience.ErrorBody(message: nil, id: errorID)
            )
            track(experienceEvent: .experienceRecovered, properties: errorProperties, shouldPublish: experience.published)
            experience.recoverableErrorID = nil
        }

    }
}

private extension ExperienceStateObserver.StateResult {
    var shouldPublish: Bool {
        switch self {
        case let .success(state):
            return state.currentExperienceData?.published ?? false
        case let .failure(error):
            return error.shouldPublish
        }
    }
}

private extension ExperienceStateMachine.ExperienceError {
    var shouldPublish: Bool {
        switch self {
        case .experienceAlreadyActive:
            return false
        case let .experience(experience, _):
            return experience.published
        case let .step(experience, _, _, _):
            return experience.published
        }
    }
}
