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
    enum Action {
        case startExperience(Experience)
        case startStep(StepReference)
        case renderStep
        case endExperience
        case reset
        case reportError(ExperienceError, fatal: Bool)
    }
}
