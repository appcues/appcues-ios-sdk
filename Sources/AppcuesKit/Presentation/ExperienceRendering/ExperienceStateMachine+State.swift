//
//  ExperienceStateMachine+State.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ExperienceStateMachine {
    enum State {
        case idling
        case beginningExperience(ExperienceData)
        case beginningStep(ExperienceData, Experience.StepIndex, ExperiencePackage, isFirst: Bool)
        case renderingStep(ExperienceData, Experience.StepIndex, ExperiencePackage, isFirst: Bool)
        case endingStep(ExperienceData, Experience.StepIndex, ExperiencePackage, markComplete: Bool)
        case endingExperience(ExperienceData, Experience.StepIndex, markComplete: Bool)

        var currentExperienceData: ExperienceData? {
            switch self {
            case .idling:
                return nil
            case .beginningExperience(let experienceData),
                    .beginningStep(let experienceData, _, _, _),
                    .renderingStep(let experienceData, _, _, _),
                    .endingStep(let experienceData, _, _, _),
                    .endingExperience(let experienceData, _, _):
                return experienceData
            }
        }

        var currentStepIndex: Experience.StepIndex? {
            switch self {
            case .idling, .beginningExperience:
                return nil
            case .beginningStep(_, let stepIndex, _, _),
                    .renderingStep(_, let stepIndex, _, _),
                    .endingStep(_, let stepIndex, _, _),
                    .endingExperience(_, let stepIndex, _):
                return stepIndex
            }
        }

        func transition(for action: Action, traitComposer: TraitComposing) -> Transition? {
            switch (self, action) {
            case let (.idling, .startExperience(experience)):
                return Transition.fromIdlingToBeginningExperience(experience)
            case let (.beginningExperience(experience), .startStep(.index(0))):
                return Transition.fromBeginningExperienceToBeginningStep(experience, traitComposer)
            case let (.beginningStep(experience, stepIndex, package, isFirst), .renderStep):
                return Transition(toState: .renderingStep(experience, stepIndex, package, isFirst: isFirst))
            case let (.renderingStep(experience, stepIndex, package, _), .startStep(stepRef)):
                return Transition.fromRenderingStepToEndingStep(experience, stepIndex, package, stepRef)
            case let (.renderingStep(experience, stepIndex, package, _), .endExperience(markComplete)):
                return Transition(
                    toState: .endingStep(experience, stepIndex, package, markComplete: markComplete),
                    sideEffect: .continuation(.endExperience(markComplete: markComplete))
                )
            case let (.endingStep(experience, stepIndex, package, _), .endExperience(markComplete)):
                return Transition(
                    toState: .endingExperience(experience, stepIndex, markComplete: markComplete),
                    sideEffect: .dismissContainer(package, continuation: .reset)
                )
            case let (.endingStep(experience, currentIndex, _, _), .startStep(stepRef)):
                return Transition.fromEndingStepToBeginningStep(experience, currentIndex, stepRef, traitComposer)
            case let (.endingExperience(experience, _, markComplete), .reset):
                var sideEffect: SideEffect?
                if markComplete {
                    sideEffect = .processActions(experience.postExperienceActions)
                }
                return Transition(toState: .idling, sideEffect: sideEffect)

            // Error cases
            case let (_, .startExperience(experience)):
                return Transition(toState: nil, sideEffect: .error(.experienceAlreadyActive(ignoredExperience: experience), reset: false))
            case let (_, .reportError(error, fatal)):
                // Don't transition directly to .idling for fatal errors because that removes
                // obsevers before they're notified of the error by the side effect.
                return Transition(toState: nil, sideEffect: .error(error, reset: fatal))
            default:
                return nil
            }
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceStateMachine.State: Equatable {
    static func == (lhs: ExperienceStateMachine.State, rhs: ExperienceStateMachine.State) -> Bool {
        switch (lhs, rhs) {
        case (.idling, .idling):
            return true
        case let (.beginningExperience(experience1), .beginningExperience(experience2)):
            return experience1.id == experience2.id
        case let (.beginningStep(experience1, stepIndex1, _, isFirst1), .beginningStep(experience2, stepIndex2, _, isFirst2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2 && isFirst1 == isFirst2
        case let (.renderingStep(experience1, stepIndex1, _, isFirst1), .renderingStep(experience2, stepIndex2, _, isFirst2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2 && isFirst1 == isFirst2
        case let (.endingStep(experience1, stepIndex1, _, markComplete1), .endingStep(experience2, stepIndex2, _, markComplete2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2 && markComplete1 == markComplete2
        case let (.endingExperience(experience1, stepIndex1, markComplete1), .endingExperience(experience2, stepIndex2, markComplete2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2 && markComplete1 == markComplete2
        default:
            return false
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceStateMachine.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .idling:
            return ".idling"
        case let .beginningExperience(experience):
            return ".beginningExperience(experienceID: \(experience.id.uuidString))"
        case let .beginningStep(experience, stepIndex, _, _):
            return ".beginningStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .renderingStep(experience, stepIndex, _, _):
            return ".renderingStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .endingStep(experience, stepIndex, _, markComplete):
            return ".endingStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex), markComplete: \(markComplete))"
        case let .endingExperience(experience, _, markComplete):
            return ".endingExperience(experienceID: \(experience.id.uuidString), markComplete: \(markComplete))"
        }
    }
}

// MARK: - Complex Transitions

@available(iOS 13.0, *)
extension ExperienceStateMachine.Transition {
    static func fromIdlingToBeginningExperience(_ experience: ExperienceData) -> Self {
        // handle errors that occurred prior to starting the experience - such as flow deserialization issues
        if let error = experience.error, !error.isEmpty {
            return .init(toState: nil, sideEffect: .error(.experience(experience, error), reset: true))
        }

        guard !experience.steps.isEmpty else {
            return .init(toState: nil, sideEffect: .error(.experience(experience, "Experience has 0 steps"), reset: true))
        }

        return .init(
           toState: .beginningExperience(experience),
           sideEffect: .continuation(.startStep(.index(0)))
       )
    }

    static func fromBeginningExperienceToBeginningStep(_ experience: ExperienceData, _ traitComposer: TraitComposing) -> Self {
        let stepIndex = Experience.StepIndex.initial
        do {
            let package = try traitComposer.package(experience: experience, stepIndex: stepIndex)
            return .init(
                toState: .beginningStep(experience, stepIndex, package, isFirst: true),
                sideEffect: .presentContainer(experience, stepIndex, package)
            )
        } catch {
            return .init(toState: nil, sideEffect: .error(.step(experience, stepIndex, "\(error)"), reset: true))
        }
    }

    static func fromRenderingStepToEndingStep(
        _ experience: ExperienceData, _ stepIndex: Experience.StepIndex, _ package: ExperiencePackage, _ stepRef: StepReference
    ) -> Self {
        guard let newStepIndex = stepRef.resolve(experience: experience, currentIndex: stepIndex) else {
            if stepRef == .offset(1) && experience.stepIndices.last == stepIndex {
                return .init(
                    toState: .endingStep(experience, stepIndex, package, markComplete: true),
                    sideEffect: .continuation(.endExperience(markComplete: true))
                )
            }

            return .init(toState: nil, sideEffect: .error(.step(experience, stepIndex, "Step at \(stepRef) does not exist"), reset: false))
        }

        let sideEffect: ExperienceStateMachine.SideEffect

        // Check if the target step is in the current container, and handle that scenario
        if let stepID = experience.step(at: newStepIndex)?.id, let pageIndex = package.steps.firstIndex(where: { $0.id == stepID }) {
            sideEffect = .navigateInContainer(package, pageIndex: pageIndex)
        } else {
            sideEffect = .dismissContainer(package, continuation: .startStep(stepRef))
        }

        // Moving to a new step is an interaction that indicates the ending step is completed
        // unless the step reference explicitly has an offset that's negative.
        return .init(toState: .endingStep(experience, stepIndex, package, markComplete: newStepIndex > stepIndex), sideEffect: sideEffect)
    }

    static func fromEndingStepToBeginningStep(
        _ experience: ExperienceData, _ currentIndex: Experience.StepIndex, _ stepRef: StepReference, _ traitComposer: TraitComposing
    ) -> Self {
        guard let stepIndex = stepRef.resolve(experience: experience, currentIndex: currentIndex) else {
            return .init(
                toState: nil,
                sideEffect: .error(.step(experience, currentIndex, "Step at \(stepRef) does not exist"), reset: false))
        }

        do {
            let package = try traitComposer.package(experience: experience, stepIndex: stepIndex)
            return .init(
                toState: .beginningStep(experience, stepIndex, package, isFirst: false),
                sideEffect: .presentContainer(experience, stepIndex, package)
            )
        } catch {
            return .init(toState: nil, sideEffect: .error(.step(experience, stepIndex, "\(error)"), reset: true))
        }
    }
}
