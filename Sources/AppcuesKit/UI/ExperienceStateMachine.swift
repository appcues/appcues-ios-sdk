//
//  ExperienceStateMachine.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class ExperienceStateMachine {

    enum ErrorType: Equatable {
        case experience
        case step(Experience.StepIndex)
    }

    enum ExperienceState {
        case empty
        case begin(Experience)
        case beginStep(StepReference)
        case renderStep(Experience, Experience.StepIndex, ExperiencePackage, isFirst: Bool)
        case endStep(Experience, Experience.StepIndex, ExperiencePackage)
        case error(Experience, ErrorType, String)
        case end(Experience)
    }

    private let config: Appcues.Config
    private let traitComposer: TraitComposing
    private let storage: DataStoring

    private var stateObservers: [StateObserver] = []
    private(set) var currentState: ExperienceState {
        didSet {
            // Call each observers and filter out ones that been satisfied
            stateObservers = stateObservers.filter { !$0.evaluateIfSatisfied(currentState) }
            // Remove all observers when the state machine resets
            if currentState == .empty {
                stateObservers.removeAll()
            }
        }
    }

    weak var experienceLifecycleEventDelegate: ExperienceEventDelegate?
    weak var clientAppcuesDelegate: AppcuesExperienceDelegate?
    weak var clientControllerDelegate: AppcuesExperienceDelegate?

    init(container: DIContainer) {
        config = container.resolve(Appcues.Config.self)
        traitComposer = container.resolve(TraitComposing.self)
        storage = container.resolve(DataStoring.self)

        currentState = .empty
    }

    /// Transition to a new state.
    /// - Parameters:
    ///   - newState: `ExperienceState` to attempt a transition to.
    ///   - observer: Block that's called on each state change, or if no state change occurs (represented by a `nil` value).
    ///   Must return `true` iff the observer is complete and should be removed.
    func transitionAndObserve(to newState: ExperienceState, observer: @escaping (ExperienceState?) -> Bool) {
        let observer = StateObserver(observer)
        stateObservers.append(observer)

        let didStateChange = transition(to: newState)

        if !didStateChange {
            let observerIsSatisfiedByFailure = observer.evaluateIfSatisfied(nil)
            if observerIsSatisfiedByFailure {
                stateObservers = stateObservers.filter { $0 !== observer }
            }
        }
    }

    /// Returns `false`if no change to the state occured.
    @discardableResult
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func transition(to newState: ExperienceState) -> Bool {
        switch (currentState, newState) {

        // MARK: Standard flow
        case let (.empty, .begin(experience)):
            guard !experience.steps.isEmpty else {
                return transition(to: .error(experience, .experience, "No steps"))
            }
            currentState = newState
            handleBegin(experience)
        case let (.begin(experience), .beginStep(.index(0))):
            currentState = newState
            handleBeginStep(experience, .initial, isFirst: true)
        case let (.beginStep, .renderStep(experience, stepIndex, package, _)):
            currentState = newState
            handleRenderStep(experience, stepIndex, package)
        case let (.renderStep(experience, currentIndex, package, _), .beginStep(stepRef)):
            guard let stepIndex = stepRef.resolve(experience: experience, currentIndex: currentIndex) else {
                return transition(to: .error(experience, .experience, "Step at \(stepRef) does not exist"))
            }
            // Check if the target step is in the current container, and handle that scenario
            if let targetID = experience.step(at: stepIndex)?.id, let pageIndex = package.steps.firstIndex(where: { $0.id == targetID }) {
                package.containerController.navigate(to: pageIndex, animated: true)
            } else {
                // If currently rendering, but trying to begin a new step, go through post-render first
                currentState = .endStep(experience, currentIndex, package)
                handleEndStep(package, nextState: newState)
            }
        case let (.renderStep, .endStep(experience, _, package)):
            // Note: this transition is supported even if it's not currently in use.
            currentState = newState
            handleEndStep(package, nextState: .end(experience))
        case let (.endStep(experience, currentIndex, _), .beginStep(stepRef)):
            guard let stepIndex = stepRef.resolve(experience: experience, currentIndex: currentIndex) else {
                return transition(to: .error(experience, .experience, "Step at \(stepRef) does not exist"))
            }
            currentState = newState
            handleBeginStep(experience, stepIndex)
        case let (.endStep, .end(experience)):
            currentState = newState
            handleEnd(experience)
        case let (.renderStep, .end(experience)):
            // Case triggered by containerDidDisappear (`UIViewController.dismiss()` called from outside state machine)
            currentState = newState
            handleEnd(experience)
        case (.end, .empty):
            currentState = newState

        // MARK: Special cases
        case let (.renderStep(_, _, package, _), .empty):
            // If currently rendering, but trying to dismiss the entire experience, call the dismisser
            // to trigger the `ExperienceContainerLifecycleHandler` handling of the dismissal.
            // Don't set `currentState` here because the lifecycle handler will take care of it.
            package.dismisser(nil)
        // MARK: Errors
        case let (_, .error(experience, errorType, reason)):
            // any state can transition to error
            currentState = newState
            handleStepError(experience, errorType, reason)
        case let (.error, .end(experience)):
            currentState = newState
            handleEnd(experience)

        // MARK: Invalid state transitions
        case let (_, .begin(experience)):
            experienceLifecycleEventDelegate?.lifecycleEvent(.experienceError(experience, "experience already active"))
            return false
        case (.empty, _):
            config.logger.error("Trying to show experience step when no experience is active")
            return false
        default:
            config.logger.error(
                "Unhandled state machine transition from %{public}s to %{public}s",
                currentState.description,
                newState.description)
            return false
        }

        return true
    }

    // MARK: - Transition Handlers

    private func handleBegin(_ experience: Experience) {
        transition(to: .beginStep(.index(0)))
    }

    private func handleBeginStep(_ experience: Experience, _ stepIndex: Experience.StepIndex, isFirst: Bool = false) {
        do {
            let package = try traitComposer.package(experience: experience, stepIndex: stepIndex)
            self.transition(to: .renderStep(
                experience,
                stepIndex,
                package,
                isFirst: isFirst))
        } catch {
            self.transition(to: .error(experience, .step(stepIndex), "\(error)"))
        }
    }

    private func handleRenderStep(_ experience: Experience, _ stepIndex: Experience.StepIndex, _ package: ExperiencePackage) {
        if let topController = UIApplication.shared.topViewController() {
            clientControllerDelegate = topController as? AppcuesExperienceDelegate
            if !canDisplay(experience: experience) {
                transition(to: .error(experience, .step(stepIndex), "Step blocked by app"))
                return
            }
        }

        package.containerController.lifecycleHandler = self

        // This flag tells automatic screen tracking to ignore screens that the SDK is presenting
        objc_setAssociatedObject(package.wrapperController, &UIKitScreenTracker.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

        do {
            try package.presenter(nil)
        } catch {
            self.transition(to: .error(experience, .step(stepIndex), "\(error)"))
        }

        storage.lastContentShownAt = Date()
    }

    private func handleEndStep(_ package: ExperiencePackage, nextState: ExperienceState) {
        package.dismisser {
            self.transition(to: nextState)
        }
    }

    private func handleEnd(_ experience: Experience) {
        transition(to: .empty)
    }

    private func handleStepError(_ experience: Experience, _ errorType: ErrorType, _ message: String) {
        switch errorType {
        case .experience:
            experienceLifecycleEventDelegate?.lifecycleEvent(.experienceError(experience, "\(message)"))
        case .step(let stepIndex):
            experienceLifecycleEventDelegate?.lifecycleEvent(.stepError(experience, stepIndex, "\(message)"))
        }
        transition(to: .end(experience))
    }
}

// MARK: - ExperienceContainerLifecycleHandler

extension ExperienceStateMachine: ExperienceContainerLifecycleHandler {
    // MARK: Step Lifecycle

    func containerWillAppear() {
        guard case let .renderStep(_, _, package, isFirst) = currentState else { return }
        guard package.wrapperController.isBeingPresented else { return }

        if isFirst {
            experienceWillAppear()
        }
    }

    func containerDidAppear() {
        guard case let .renderStep(experience, stepIndex, package, isFirst) = currentState else { return }
        guard package.wrapperController.isBeingPresented else { return }

        if isFirst {
            experienceLifecycleEventDelegate?.lifecycleEvent(.experienceStarted(experience))
            experienceDidAppear()
        }

        experienceLifecycleEventDelegate?.lifecycleEvent(.stepSeen(experience, stepIndex))
    }

    func containerWillDisappear() {
        switch currentState {
        case let .endStep(_, _, package):
            guard package.wrapperController.isBeingDismissed == true else { return }
        case let .renderStep(_, _, package, _):
            guard package.wrapperController.isBeingDismissed == true else { return }
            // Dismissed outside state machine post-render
            experienceWillDisappear()
        default:
            break
        }
    }

    func containerDidDisappear() {
        switch currentState {
        case let .endStep(experience, stepIndex, package):
            guard package.wrapperController.isBeingDismissed == true else { return }
            experienceLifecycleEventDelegate?.lifecycleEvent(.stepCompleted(experience, stepIndex))
        case let .renderStep(experience, stepIndex, package, _):
            guard package.wrapperController.isBeingDismissed == true else { return }
            // Dismissed outside state machine post-render
            experienceDidDisappear()
            if stepIndex == experience.stepIndices.last {
                experienceLifecycleEventDelegate?.lifecycleEvent(.stepCompleted(experience, stepIndex))
                experienceLifecycleEventDelegate?.lifecycleEvent(.experienceCompleted(experience))
            } else {
                experienceLifecycleEventDelegate?.lifecycleEvent(.experienceDismissed(experience, stepIndex))
            }

            transition(to: .end(experience))
        default:
            break
        }
    }

    func containerNavigated(from oldPageIndex: Int, to newPageIndex: Int) {
        guard case let .renderStep(experience, stepIndex, package, _) = currentState else { return }

        let targetStepId = package.steps[newPageIndex].id

        // Analytics for completed step
        experienceLifecycleEventDelegate?.lifecycleEvent(.stepCompleted(experience, stepIndex))

        if let newStepIndex = experience.stepIndex(for: targetStepId) {
            // Analytics for new step
            experienceLifecycleEventDelegate?.lifecycleEvent(.stepSeen(experience, newStepIndex))

            // We don't want the state machine to generally support a .renderStep->.renderStep transition,
            // so we're shortcutting it internally here by setting currentState directly.
            currentState = .renderStep(experience, newStepIndex, package, isFirst: false)
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

private extension ExperienceStateMachine {
    class StateObserver {
        let evaluateIfSatisfied: (ExperienceState?) -> Bool

        init(_ evaluateIfSatisfied: @escaping (ExperienceState?) -> Bool) {
            self.evaluateIfSatisfied = evaluateIfSatisfied
        }
    }
}

extension ExperienceStateMachine.ExperienceState: Equatable {
    static func == (lhs: ExperienceStateMachine.ExperienceState, rhs: ExperienceStateMachine.ExperienceState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case let (.begin(experience1), .begin(experience2)):
            return experience1.id == experience2.id
        case let (.beginStep(stepRef1), .beginStep(stepRef2)):
            return stepRef1 == stepRef2
        case let (.renderStep(experience1, stepIndex1, _, isFirst1), .renderStep(experience2, stepIndex2, _, isFirst2)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2 && isFirst1 == isFirst2
        case let (.endStep(experience1, stepIndex1, _), .endStep(experience2, stepIndex2, _)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2
        case let (.error(experience1, errorType1, message1), .error(experience2, errorType2, message2)):
            return experience1.id == experience2.id && errorType1 == errorType2 && message1 == message2
        case let (.end(experience1), .end(experience2)):
            return experience1.id == experience2.id
        default:
            return false
        }
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
        case let .error(experience, _, _):
            return ".error(experienceID: \(experience.id.uuidString))"
        case let .end(experience):
            return ".end(experienceID: \(experience.id.uuidString))"
        }
    }
}
