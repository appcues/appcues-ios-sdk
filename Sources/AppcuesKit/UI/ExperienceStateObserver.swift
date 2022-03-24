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
    func evaluateIfSatisfied(result: StateResult) -> Bool
}

extension ExperienceStateMachine {
    typealias Callback = (ExperienceStateObserver.StateResult) -> Bool

    class StateObserver: ExperienceStateObserver {
        private let callback: Callback

        init(_ evaluateIfSatisfied: @escaping Callback) {
            self.callback = evaluateIfSatisfied
        }

        func evaluateIfSatisfied(result: ExperienceStateObserver.StateResult) -> Bool {
            callback(result)
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
                trackLifecycleEvent(.experienceStarted(experience))
                trackLifecycleEvent(.stepSeen(experience, stepIndex))
            case let .success(.renderingStep(experience, stepIndex, _, isFirst: false)):
                trackLifecycleEvent(.stepSeen(experience, stepIndex))
            case let .success(.endingStep(experience, stepIndex, _)):
                trackLifecycleEvent(.stepCompleted(experience, stepIndex))
            case let .success(.endingExperience(experience, stepIndex)):
                if stepIndex == experience.stepIndices.last {
                    trackLifecycleEvent(.experienceCompleted(experience))
                } else {
                    trackLifecycleEvent(.experienceDismissed(experience, stepIndex))
                }
            case let .failure(.experience(experience, message)):
                trackLifecycleEvent(.experienceError(experience, "\(message)"))
            case let .failure(.step(experience, stepIndex, message)):
                trackLifecycleEvent(.stepError(experience, stepIndex, "\(message)"))
            case .failure(.noTransition):
                break
            }

            // Always continue observing
            return false
        }

        func trackLifecycleEvent(_ event: ExperienceLifecycleEvent) {
            analyticsPublisher.track(name: event.name, properties: event.properties, sync: false)
        }
    }
}
