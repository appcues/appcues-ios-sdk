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
        case let .success(.beginningExperience(experience)),
            let .success(.beginningStep(experience, _, _, _)),
            let .success(.renderingStep(experience, _, _, _)),
            let .success(.endingStep(experience, _, _)),
            let .success(.endingExperience(experience, _)),
            let .failure(.experienceAlreadyActive(ignoredExperience: experience)),
            let .failure(.step(experience, _, _)),
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
            switch result {
            case .success(.idling):
                break
            case .success(.beginningExperience):
                break
            case .success(.beginningStep):
                break
            case let .success(.renderingStep(experience, stepIndex, _, isFirst: true)):
                storage.lastContentShownAt = Date()
                trackLifecycleEvent(.experienceStarted, LifecycleEvent.properties(experience))
                trackLifecycleEvent(.stepSeen, LifecycleEvent.properties(experience, stepIndex))
            case let .success(.renderingStep(experience, stepIndex, _, isFirst: false)):
                trackLifecycleEvent(.stepSeen, LifecycleEvent.properties(experience, stepIndex))
            case let .success(.endingStep(experience, stepIndex, _)):
                trackLifecycleEvent(.stepCompleted, LifecycleEvent.properties(experience, stepIndex))
            case let .success(.endingExperience(experience, stepIndex)):
                if stepIndex == experience.stepIndices.last {
                    trackLifecycleEvent(.experienceCompleted, LifecycleEvent.properties(experience))
                } else {
                    trackLifecycleEvent(.experienceDismissed, LifecycleEvent.properties(experience, stepIndex))
                }
            case let .failure(.experience(experience, message)):
                trackLifecycleEvent(.experienceError, LifecycleEvent.properties(experience, error: "\(message)"))
            case let .failure(.step(experience, stepIndex, message)):
                trackLifecycleEvent(.stepError, LifecycleEvent.properties(experience, stepIndex, error: "\(message)"))
            case .failure(.noTransition):
                break
            case .failure(.experienceAlreadyActive):
                break
            }

            // Always continue observing
            return false
        }

        func trackLifecycleEvent(_ name: LifecycleEvent, _ properties: [String: Any]) {
            analyticsPublisher.track(name: name.rawValue, properties: properties, interactive: false)
        }
    }
}
