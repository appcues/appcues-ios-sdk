//
//  ExperienceStateMachine+ExperienceError.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension ExperienceStateMachine {
    enum ExperienceError: Error {
        case noTransition
        case experienceAlreadyActive(ignoredExperience: Experience)
        case experience(Experience, String)
        case step(Experience, Experience.StepIndex, String)
    }
}

extension ExperienceStateMachine.ExperienceError: Equatable {
    static func == (lhs: ExperienceStateMachine.ExperienceError, rhs: ExperienceStateMachine.ExperienceError) -> Bool {
        switch (lhs, rhs) {
        case (.noTransition, .noTransition):
            return true
        case let (.experienceAlreadyActive(experience1), .experienceAlreadyActive(experience2)):
            return experience1.id == experience2.id
        case let (.experience(experience1, message1), .experience(experience2, message2)):
            return experience1.id == experience2.id && message1 == message2
        case let (.step(experience1, stepIndex1, message1), .step(experience2, stepIndex2, message2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2 && message1 == message2
        default:
            return false
        }
    }
}

extension ExperienceStateMachine.ExperienceError: CustomStringConvertible {
    var description: String {
        switch self {
        case .noTransition:
            return ".noTransition"
        case let .experienceAlreadyActive(experience):
            return ".experienceAlreadyActive(ignoredExperienceID: \(experience.id.uuidString))"
        case let .experience(experience, message):
            return ".experience(experienceID: \(experience.id.uuidString), message: \(message))"
        case let .step(experience, stepIndex, message):
            return ".step(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex), message: \(message))"
        }
    }
}
