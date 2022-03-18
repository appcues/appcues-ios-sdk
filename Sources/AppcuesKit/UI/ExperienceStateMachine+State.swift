//
//  ExperienceStateMachine+State.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

extension ExperienceStateMachine {
    enum State {
        case idling
        case beginningExperience(Experience)
        case beginningStep(Experience, Experience.StepIndex, ExperiencePackage, isFirst: Bool)
        case renderingStep(Experience, Experience.StepIndex, ExperiencePackage)
        case endingStep(Experience, Experience.StepIndex, ExperiencePackage)
        case endingExperience(Experience, Experience.StepIndex)

        func transition(for action: Action, traitComposer: TraitComposing) -> Transition? {
            switch (self, action) {
            case let (.idling, .startExperience(experience)):
                return Transition.fromIdlingToBeginningExperience(experience)
            case let (.beginningExperience(experience), .startStep(.index(0))):
                return Transition.fromBeginningExperienceToBeginningStep(experience, traitComposer)
            case let (.beginningStep(experience, stepIndex, package, _), .renderStep):
                return Transition(toState: .renderingStep(experience, stepIndex, package))
            case let (.renderingStep(experience, stepIndex, package), .startStep(stepRef)):
                return Transition.fromRenderingStepToEndingStep(experience, stepIndex, package, stepRef)
            case let (.renderingStep(experience, stepIndex, package), .endExperience):
                return Transition(
                    toState: .endingStep(experience, stepIndex, package),
                    sideEffect: .continuation(.endExperience)
                )
            case let (.endingStep(experience, stepIndex, package), .endExperience):
                return Transition(
                    toState: .endingExperience(experience, stepIndex),
                    sideEffect: .dismissContainer(package, continuation: .reset)
                )
            case let (.endingStep(experience, currentIndex, _), .startStep(stepRef)):
                return Transition.fromEndingStepToBeginningStep(experience, currentIndex, stepRef, traitComposer)
            case (.endingExperience, .reset):
                return Transition(toState: .idling)

            // Error cases
            case let (_, .startExperience(experience)):
                return Transition(toState: nil, sideEffect: .error(.experience(experience, "Experience already active")))
            case let (_, .reportError(error, fatal: true)):
                return Transition(toState: .idling, sideEffect: .error(error))
            case let (_, .reportError(error, fatal: false)):
                return Transition(toState: nil, sideEffect: .error(error))
            default:
                return nil
            }
        }
    }
}

extension ExperienceStateMachine.State: Equatable {
    static func == (lhs: ExperienceStateMachine.State, rhs: ExperienceStateMachine.State) -> Bool {
        switch (lhs, rhs) {
        case (.idling, .idling):
            return true
        case let (.beginningExperience(experience1), .beginningExperience(experience2)):
            return experience1.id == experience2.id
        case let (.beginningStep(experience1, stepIndex1, _, isFirst1), .beginningStep(experience2, stepIndex2, _, isFirst2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2 && isFirst1 == isFirst2
        case let (.renderingStep(experience1, stepIndex1, _), .renderingStep(experience2, stepIndex2, _)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2
        case let (.endingStep(experience1, stepIndex1, _), .endingStep(experience2, stepIndex2, _)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2
        case let (.endingExperience(experience1, stepIndex1), .endingExperience(experience2, stepIndex2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2
        default:
            return false
        }
    }
}

extension ExperienceStateMachine.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .idling:
            return ".idling"
        case let .beginningExperience(experience):
            return ".beginningExperience(experienceID: \(experience.id.uuidString))"
        case let .beginningStep(experience, stepIndex, _, _):
            return ".beginningStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .renderingStep(experience, stepIndex, _):
            return ".renderingStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .endingStep(experience, stepIndex, _):
            return ".endingStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .endingExperience(experience, _):
            return ".endingExperience(experienceID: \(experience.id.uuidString))"
        }
    }
}

// MARK: - Complex Transitions

extension ExperienceStateMachine.Transition {
    static func fromIdlingToBeginningExperience(_ experience: Experience) -> Self {
        guard !experience.steps.isEmpty else {
            return .init(toState: nil, sideEffect: .error(.experience(experience, "Experience has 0 steps")))
        }

        return .init(
           toState: .beginningExperience(experience),
           sideEffect: .continuation(.startStep(.index(0)))
       )
    }

    static func fromBeginningExperienceToBeginningStep(_ experience: Experience, _ traitComposer: TraitComposing) -> Self {
        let stepIndex = Experience.StepIndex.initial
        do {
            let package = try traitComposer.package(experience: experience, stepIndex: stepIndex)
            return .init(
                toState: .beginningStep(experience, stepIndex, package, isFirst: true),
                sideEffect: .presentContainer(experience, stepIndex, package)
            )
        } catch {
            return .init(toState: .idling, sideEffect: .error(.step(experience, stepIndex, "\(error)")))
        }
    }

    static func fromRenderingStepToEndingStep(
        _ experience: Experience, _ stepIndex: Experience.StepIndex, _ package: ExperiencePackage, _ stepRef: StepReference
    ) -> Self {
        guard let newStepIndex = stepRef.resolve(experience: experience, currentIndex: stepIndex) else {
            return .init(toState: nil, sideEffect: .error(.step(experience, stepIndex, "Step at \(stepRef) does not exist")))
        }

        let sideEffect: ExperienceStateMachine.SideEffect

        // Check if the target step is in the current container, and handle that scenario
        if let stepID = experience.step(at: newStepIndex)?.id, let pageIndex = package.steps.firstIndex(where: { $0.id == stepID }) {
            sideEffect = .navigateInContainer(package, pageIndex: pageIndex)
        } else {
            sideEffect = .dismissContainer(package, continuation: .startStep(stepRef))
        }

        return .init(toState: .endingStep(experience, stepIndex, package), sideEffect: sideEffect)
    }

    static func fromEndingStepToBeginningStep(
        _ experience: Experience, _ currentIndex: Experience.StepIndex, _ stepRef: StepReference, _ traitComposer: TraitComposing
    ) -> Self {
        guard let stepIndex = stepRef.resolve(experience: experience, currentIndex: currentIndex) else {
            return .init(toState: nil, sideEffect: .error(.step(experience, currentIndex, "Step at \(stepRef) does not exist")))
        }

        do {
            let package = try traitComposer.package(experience: experience, stepIndex: stepIndex)
            return .init(
                toState: .beginningStep(experience, stepIndex, package, isFirst: false),
                sideEffect: .presentContainer(experience, stepIndex, package)
            )
        } catch {
            return .init(toState: .idling, sideEffect: .error(.step(experience, stepIndex, "\(error)")))
        }
    }
}
