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
    func evaluateIfSatisfied(result: StateResult, machine: ExperienceStateMachine) -> Bool
}

extension ExperienceStateMachine {
    typealias Callback = (ExperienceStateObserver.StateResult, ExperienceStateMachine) -> Bool

    class StateObserver: ExperienceStateObserver {
        private let callback: Callback

        init(_ evaluateIfSatisfied: @escaping Callback) {
            self.callback = evaluateIfSatisfied
        }

        func evaluateIfSatisfied(result: ExperienceStateObserver.StateResult, machine: ExperienceStateMachine) -> Bool {
            callback(result, machine)
        }
    }

    class AnalyticsObserver: ExperienceStateObserver {
        func evaluateIfSatisfied(result: ExperienceStateObserver.StateResult, machine: ExperienceStateMachine) -> Bool {
            switch result {
            case .success(.idling):
                break
            case let .success(.beginningExperience(experience)):
                machine.experienceLifecycleEventDelegate?.lifecycleEvent(.experienceStarted(experience))
            case .success(.beginningStep):
                break
            case let .success(.renderingStep(experience, stepIndex, _)):
                machine.experienceLifecycleEventDelegate?.lifecycleEvent(.stepSeen(experience, stepIndex))
            case let .success(.endingStep(experience, stepIndex, _)):
                machine.experienceLifecycleEventDelegate?.lifecycleEvent(.stepCompleted(experience, stepIndex))
            case let .success(.endingExperience(experience, stepIndex)):
                if stepIndex == experience.stepIndices.last {
                    machine.experienceLifecycleEventDelegate?.lifecycleEvent(.experienceCompleted(experience))
                } else {
                    machine.experienceLifecycleEventDelegate?.lifecycleEvent(.experienceDismissed(experience, stepIndex))
                }
            case let .failure(.experience(experience, message)):
                machine.experienceLifecycleEventDelegate?.lifecycleEvent(.experienceError(experience, "\(message)"))
            case let .failure(.step(experience, stepIndex, message)):
                machine.experienceLifecycleEventDelegate?.lifecycleEvent(.stepError(experience, stepIndex, "\(message)"))
            case .failure(.noTransition):
                break
            }

            // Always continue observing
            return false
        }
    }
}
