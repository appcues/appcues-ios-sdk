//
//  ExperienceStateMachine+Action.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension ExperienceStateMachine {
    enum Action {
        case startExperience(Experience)
        case startStep(StepReference)
        case renderStep
        case endExperience
        case reset
        case reportError(ExperienceError, fatal: Bool)
    }
}

extension ExperienceStateMachine.Action: Equatable {
    static func == (lhs: ExperienceStateMachine.Action, rhs: ExperienceStateMachine.Action) -> Bool {
        switch (lhs, rhs) {
        case let (.startExperience(experience1), .startExperience(experience2)):
            return experience1.id == experience2.id
        case let (.startStep(stepRef1), .startStep(stepRef2)):
            return stepRef1 == stepRef2
        case (.renderStep, .renderStep),
            (.endExperience, .endExperience),
            (.reset, .reset):
            return true
        case let (.reportError(error1), .reportError(error2)):
            return error1 == error2
        default:
            return false
        }
    }
}
