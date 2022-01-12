//
//  ExperienceStateMachine.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class ExperienceStateMachine {

    enum ExperienceState {
        case empty
        case begin(Experience)
        case beginStep(StepReference)
        case renderStep(Experience, Int, UIViewController, isFirst: Bool)
        case endStep(Experience, Int, UIViewController)
        case stepError(Experience, Int, String)
        case end(Experience)
    }

    private let config: Appcues.Config
    private let traitRegistry: TraitRegistry
    private let actionRegistry: ActionRegistry
    private let storage: DataStoring

    private(set) var currentState: ExperienceState

    weak var experienceLifecycleEventDelegate: ExperienceEventDelegate?
    weak var clientAppcuesDelegate: AppcuesExperienceDelegate?
    weak var clientControllerDelegate: AppcuesExperienceDelegate?

    init(container: DIContainer) {
        config = container.resolve(Appcues.Config.self)
        traitRegistry = container.resolve(TraitRegistry.self)
        actionRegistry = container.resolve(ActionRegistry.self)
        storage = container.resolve(DataStoring.self)

        currentState = .empty
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func transition(to newState: ExperienceState) {
        if case let .begin(experience) = newState {
            experienceLifecycleEventDelegate?.lifecycleEvent(.flowAttempted(experience))
        }

        switch (currentState, newState) {

        // MARK: Standard flow
        case let (.empty, .begin(experience)):
            currentState = newState
            handleBegin(experience)
        case let (.begin(experience), .beginStep(.index(0))):
            currentState = newState
            handleBeginStep(experience, 0, isFirst: true)
        case let (.beginStep, .renderStep(experience, stepIndex, controller, _)):
            currentState = newState
            handleRenderStep(experience, stepIndex, controller)
        case let (.renderStep(experience, stepIndex, controller, _), .beginStep):
            // If currently rendering, but trying to begin a new step, go through post-render first
            currentState = .endStep(experience, stepIndex, controller)
            handleEndStep(experience, stepIndex, controller, nextState: newState)
        case let (.renderStep, .endStep(experience, stepIndex, controller)):
            currentState = newState
            handleEndStep(experience, stepIndex, controller, nextState: .end(experience))
        case let (.endStep(experience, currentIndex, _), .beginStep(stepRef)):
            let stepIndex = stepRef.resolve(currentIndex: currentIndex)
            if experience.steps.indices.contains(stepIndex) {
                currentState = newState
                handleBeginStep(experience, stepIndex)
            } else {
                transition(to: .stepError(experience, currentIndex, "Flow error: step index \(stepIndex) does not exist"))
            }
        case let (.endStep, .end(experience)):
            currentState = newState
            handleEnd(experience)
        case let (.renderStep, .end(experience)):
            // Case triggered by stepDidDisappear (`UIViewController.dismiss()` called from outside state machine)
            currentState = newState
            handleEnd(experience)
        case (.end, .empty):
            currentState = newState

        // MARK: Special cases
        case let (.renderStep(_, _, controller, _), .empty):
            // If currently rendering, but trying to dismiss the entire experience, call `UIViewController.dismiss()`
            // to trigger the `ExperienceContainerLifecycleHandler` handling of the dismissal.
            // Don't set `currentState` here because the lifecycle handler will take care of it
            controller.dismiss(animated: true)

        // MARK: Errors
        case let (_, .stepError(experience, stepIndex, reason)):
            // any state can transition to error
            currentState = newState
            handleStepError(experience, stepIndex, reason)
        case let (.stepError(_, _, message), .end(experience)):
            currentState = newState
            experienceLifecycleEventDelegate?.lifecycleEvent(.flowError(experience, message))
            experienceLifecycleEventDelegate?.lifecycleEvent(.flowAborted(experience))
            handleEnd(experience)

        // MARK: Invalid state transitions
        case let (_, .begin(experience)):
            experienceLifecycleEventDelegate?.lifecycleEvent(.flowError(experience, "experience already active"))
            experienceLifecycleEventDelegate?.lifecycleEvent(.flowAborted(experience))
        case (.empty, _):
            config.logger.error("Trying to show experience step when no experience is active")
        default:
            config.logger.error(
                "Unhandled state machine transition from %{public}s to %{public}s",
                currentState.description,
                newState.description)
        }
    }

    // MARK: - Transition Handlers

    private func handleBegin(_ experience: Experience) {
        transition(to: .beginStep(.index(0)))
    }

    private func handleBeginStep(_ experience: Experience, _ stepIndex: Int, isFirst: Bool = false) {
        let step = experience.steps[stepIndex]

        DispatchQueue.main.async {
            let viewModel = ExperienceStepViewModel(step: step, actionRegistry: self.actionRegistry)
            let stepViewController = ExperiencePagingViewController(viewModel: viewModel)
            stepViewController.lifecycleHandler = self
            let wrappedViewController = self.traitRegistry.apply(step.traits, to: stepViewController)

            // this flag tells automatic screen tracking to ignore screens that the SDK is presenting
            objc_setAssociatedObject(wrappedViewController, &UIKitScreenTracker.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

            self.transition(to: .renderStep(experience, stepIndex, wrappedViewController, isFirst: isFirst))
        }
    }

    private func handleRenderStep(_ experience: Experience, _ stepIndex: Int, _ controller: UIViewController) {
        experienceLifecycleEventDelegate?.lifecycleEvent(.stepAttempted(experience, stepIndex))

        guard let topController = UIApplication.shared.topViewController() else {
            transition(to: .stepError(experience, stepIndex, "No top VC found"))
            return
        }

        clientControllerDelegate = topController as? AppcuesExperienceDelegate

        guard canDisplay(experience: experience) else {
            transition(to: .stepError(experience, stepIndex, "Step blocked by app"))
            return
        }

        topController.present(controller, animated: true)

        storage.lastContentShownAt = Date()
    }

    private func handleEndStep(
        _ experience: Experience, _ stepIndex: Int, _ controller: UIViewController, nextState: ExperienceState
    ) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true) {
                self.transition(to: nextState)
            }
        }
    }

    private func handleEnd(_ experience: Experience) {
        transition(to: .empty)
    }

    private func handleStepError(_ experience: Experience, _ stepIndex: Int, _ message: String) {
        experienceLifecycleEventDelegate?.lifecycleEvent(.stepError(experience, stepIndex, message))
        experienceLifecycleEventDelegate?.lifecycleEvent(.stepAborted(experience, stepIndex))
        transition(to: .end(experience))
    }
}

// MARK: - ExperienceContainerLifecycleHandler

extension ExperienceStateMachine: ExperienceContainerLifecycleHandler {
    // MARK: Step Lifecycle

    func containerWillAppear() {
        guard case let .renderStep(_, _, controller, isFirst) = currentState else { return }
        guard controller.isBeingPresented else { return }

        if isFirst {
            experienceWillAppear()
        }
    }

    func containerDidAppear() {
        guard case let .renderStep(experience, stepIndex, controller, isFirst) = currentState else { return }
        guard controller.isBeingPresented else { return }

        if isFirst {
            experienceLifecycleEventDelegate?.lifecycleEvent(.flowStarted(experience))
            experienceDidAppear()
        }

        experienceLifecycleEventDelegate?.lifecycleEvent(.stepStarted(experience, stepIndex))
    }

    func containerWillDisappear() {
        switch currentState {
        case let .endStep(_, _, controller):
            guard controller.isBeingDismissed == true else { return }
        case let .renderStep(_, _, controller, _):
            guard controller.isBeingDismissed == true else { return }
            // Dismissed outside state machine post-render
            experienceWillDisappear()
        default:
            break
        }
    }

    func containerDidDisappear() {
        switch currentState {
        case let .endStep(experience, stepIndex, controller):
            guard controller.isBeingDismissed == true else { return }
            experienceLifecycleEventDelegate?.lifecycleEvent(.stepInteracted(experience, stepIndex))
            experienceLifecycleEventDelegate?.lifecycleEvent(.stepCompleted(experience, stepIndex))
        case let .renderStep(experience, stepIndex, controller, _):
            guard controller.isBeingDismissed == true else { return }
            // Dismissed outside state machine post-render
            experienceDidDisappear()
            if stepIndex == experience.steps.count - 1 {
                experienceLifecycleEventDelegate?.lifecycleEvent(.stepInteracted(experience, stepIndex))
                experienceLifecycleEventDelegate?.lifecycleEvent(.stepCompleted(experience, stepIndex))
                experienceLifecycleEventDelegate?.lifecycleEvent(.flowCompleted(experience))
            } else {
                experienceLifecycleEventDelegate?.lifecycleEvent(.stepSkipped(experience, stepIndex))
                experienceLifecycleEventDelegate?.lifecycleEvent(.flowSkipped(experience))
            }

            transition(to: .end(experience))
        default:
            break
        }
    }

    // MARK: Experience Lifecycle

    func canDisplay(experience: Experience) -> Bool {
        let id = experience.id.uuidString

        if let delegate = clientControllerDelegate, !delegate.canDisplayExperience(experienceID: id) {
            return false
        }

        if let delegate = clientAppcuesDelegate, !delegate.canDisplayExperience(experienceID: id) {
            return false
        }

        return true
    }

    private func experienceWillAppear() {
        clientControllerDelegate?.experienceWillAppear()
        clientAppcuesDelegate?.experienceWillAppear()
    }

    private func experienceDidAppear() {
        clientControllerDelegate?.experienceDidAppear()
        clientAppcuesDelegate?.experienceDidAppear()
    }

    private func experienceWillDisappear() {
        clientControllerDelegate?.experienceWillDisappear()
        clientAppcuesDelegate?.experienceWillDisappear()
    }

    private func experienceDidDisappear() {
        clientControllerDelegate?.experienceDidDisappear()
        clientAppcuesDelegate?.experienceDidDisappear()
    }
}

extension ExperienceStateMachine.ExperienceState: CustomStringConvertible {
    var description: String {
        switch self {
        case .empty:
            return ".empty"
        case let .begin(experience):
            return ".begin(experienceID: \(experience.id.uuidString))"
        case let .beginStep(stepRef):
            return ".beginStep(ref: \(stepRef))"
        case let .renderStep(experience, stepIndex, _, _):
            return ".renderStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .endStep(experience, stepIndex, _):
            return ".endStep(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .stepError(experience, stepIndex, _):
            return ".stepError(experienceID: \(experience.id.uuidString), stepIndex: \(stepIndex))"
        case let .end(experience):
            return ".end(experienceID: \(experience.id.uuidString))"
        }
    }
}
