//
//  ExperienceStateObserver.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal protocol ExperienceStateObserver: AnyObject {
    typealias StateResult = Result<ExperienceStateMachine.State, ExperienceStateMachine.ExperienceError>
    func evaluateIfSatisfied(result: StateResult) -> Bool
}

@available(iOS 13.0, *)
extension Result where Success == ExperienceStateMachine.State, Failure == ExperienceStateMachine.ExperienceError {

    /// Check if the result pertains to a specific experience ID.
    func matches(instanceID: UUID?) -> Bool {
        guard let instanceID = instanceID else { return true }

        switch self {
        case .success(.idling), .failure(.noTransition):
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

@available(iOS 13.0, *)
extension ExperienceStateMachine {
    typealias Callback = (ExperienceStateObserver.StateResult) -> Bool

    class StateObserver: ExperienceStateObserver {
        private let instanceID: UUID?
        private let callback: Callback

        init(filter: UUID?, _ evaluateIfSatisfied: @escaping Callback) {
            self.instanceID = filter
            self.callback = evaluateIfSatisfied
        }

        func evaluateIfSatisfied(result: ExperienceStateObserver.StateResult) -> Bool {
            guard result.matches(instanceID: instanceID) else { return false }

            return callback(result)
        }
    }

    class AnalyticsObserver: ExperienceStateObserver {
        private let analyticsPublisher: AnalyticsPublishing
        private let storage: DataStoring

        init(container: DIContainer) {
            self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)
            self.storage = container.resolve(DataStoring.self)
        }

        func evaluateIfSatisfied(result: ExperienceStateObserver.StateResult) -> Bool {
            guard result.shouldTrack else {
                // Always continue observing
                return false
            }

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
                track(experienceEvent: .experienceStarted, properties: experienceStartProps)
                // optionally track the recovery from a render error, if it is now rendering
                trackStepRecovery(ifErrorOn: experience, stepIndex: stepIndex)
                track(experienceEvent: .stepSeen, properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex))
            case let .success(.renderingStep(experience, stepIndex, _, isFirst: false)):
                track(experienceEvent: .stepSeen, properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex))
            case let .success(.endingStep(experience, stepIndex, _, markComplete)):
                if markComplete {
                    track(experienceEvent: .stepCompleted, properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex))
                }
            case let .success(.endingExperience(experience, stepIndex, markComplete)):
                if markComplete {
                    track(experienceEvent: .experienceCompleted, properties: Dictionary(propertiesFrom: experience))
                } else {
                    track(experienceEvent: .experienceDismissed, properties: Dictionary(propertiesFrom: experience, stepIndex: stepIndex))
                }
            case .success(.failing):
                break
            case let .failure(.experience(experience, message)):
                track(experienceEvent: .experienceError, properties: Dictionary(propertiesFrom: experience, error: "\(message)"))
            case let .failure(.step(experience, stepIndex, message, recoverable)):
                trackStepError(experience: experience, stepIndex: stepIndex, message: message, recoverable: recoverable)
            case .failure(.noTransition):
                break
            case .failure(.experienceAlreadyActive):
                break
            }

            // Always continue observing
            return false
        }

        private func track(experienceEvent name: Events.Experience, properties: [String: Any]) {
            analyticsPublisher.publish(TrackingUpdate(
                type: .event(name: name.rawValue, interactive: false),
                properties: properties,
                isInternal: true
            ))
        }

        private func trackStepError(experience: ExperienceData, stepIndex: Experience.StepIndex, message: String, recoverable: Bool) {
            // guard against tracking the same step error repeatedly during retry
            // don't need to guard for published, since this function is only called private to this class
            // and the observer is only attached on published flows
            guard experience.recoverableErrorID == nil else { return }

            let errorID = UUID.create()
            if recoverable {
                experience.recoverableErrorID = errorID
            }
            let errorProperties = Dictionary(
                propertiesFrom: experience,
                stepIndex: stepIndex,
                error: Events.Experience.ErrorBody(message: message, id: errorID)
            )
            track(experienceEvent: .stepError, properties: errorProperties)
        }

        private func trackStepRecovery(ifErrorOn experience: ExperienceData, stepIndex: Experience.StepIndex) {
            // only track a recovery if we had previously captured a render error for this experience
            guard let errorID = experience.recoverableErrorID else { return }

            let errorProperties = Dictionary(
                propertiesFrom: experience,
                stepIndex: stepIndex,
                error: Events.Experience.ErrorBody(message: nil, id: errorID)
            )
            track(experienceEvent: .stepRecovered, properties: errorProperties)
            experience.recoverableErrorID = nil
        }

        func trackRecoverableError(experience: ExperienceData, message: String) {
            guard experience.published, experience.recoverableErrorID == nil else { return }

            let errorID = UUID.create()
            experience.recoverableErrorID = errorID
            let errorProperties = Dictionary(
                propertiesFrom: experience,
                error: Events.Experience.ErrorBody(message: message, id: errorID)
            )
            track(experienceEvent: .experienceError, properties: errorProperties)
        }

        func trackErrorRecovery(ifErrorOn experience: ExperienceData) {
            guard experience.published, let errorID = experience.recoverableErrorID else { return }

            let errorProperties = Dictionary(
                propertiesFrom: experience,
                error: Events.Experience.ErrorBody(message: nil, id: errorID)
            )
            track(experienceEvent: .experienceRecovered, properties: errorProperties)
            experience.recoverableErrorID = nil
        }

    }
}

@available(iOS 13.0, *)
private extension ExperienceStateObserver.StateResult {
    var shouldTrack: Bool {
        switch self {
        case let .success(state):
            return state.currentExperienceData?.published ?? false
        case let .failure(error):
            return error.shouldTrack
        }
    }
}

@available(iOS 13.0, *)
private extension ExperienceStateMachine.ExperienceError {
    var shouldTrack: Bool {
        switch self {
        case .noTransition:
            return false
        case .experienceAlreadyActive:
            return false
        case let .experience(experience, _):
            return experience.published
        case let .step(experience, _, _, _):
            return experience.published
        }
    }
}
