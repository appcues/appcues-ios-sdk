//
//  ExperienceStateMachine+Action.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ExperienceStateMachine {
    indirect enum Action {
        case startExperience(ExperienceData)
        case startStep(StepReference)
        case renderStep
        case endExperience(markComplete: Bool)
        case reset
        case reportError(error: ExperienceError, retryEffect: SideEffect)
        case retry
    }
}
