//
//  ExperienceStateMachine.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperienceStateMachine {

    private let config: Appcues.Config
    private let traitComposer: TraitComposing
    private let actionRegistry: ActionRegistry

    private(set) var stateObservers: [ExperienceStateObserver] = []

    private(set) var state: State {
        didSet {
            // Call each observer and filter out ones that been satisfied
            stateObservers = stateObservers.filter { !$0.evaluateIfSatisfied(result: .success(state)) }
            // Remove all observers when the state machine resets
            if state == .idling {
                stateObservers.removeAll()
            }
        }
    }

    weak var clientAppcuesDelegate: AppcuesExperienceDelegate?
    weak var clientControllerDelegate: AppcuesExperienceDelegate?

    init(container: DIContainer, initialState: State = .idling) {
        config = container.resolve(Appcues.Config.self)
        traitComposer = container.resolve(TraitComposing.self)
        actionRegistry = container.resolve(ActionRegistry.self)

        state = initialState
    }

    /// Transition to a new state.
    ///
    /// Any side effects in `observer` should be dispatched asynchronously to allow the observer processing to complete
    /// before the side effect spawns a new action.
    ///
    /// - Parameters:
    ///   - newState: `ExperienceState` to attempt a transition to.
    ///   - observer: Block that's called on each state change, or if no state change occurs (represented by a `nil` value).
    ///   Must return `true` iff the observer is complete and should be removed.
    func transitionAndObserve(_ action: Action, filter: UUID? = nil, observer: @escaping (ExperienceStateObserver.StateResult) -> Bool) {
        let observer = StateObserver(filter: filter, observer)
        addObserver(observer)

        do {
            try transition(action)
        } catch {
            let error = ExperienceError.noTransition(currentState: state)
            let observerIsSatisfiedByFailure = observer.evaluateIfSatisfied(result: .failure(error))
            if observerIsSatisfiedByFailure {
                stateObservers = stateObservers.filter { $0 !== observer }
            }
        }
    }

    func transition(_ action: Action) throws {
        guard let transition = state.transition(for: action, traitComposer: traitComposer) else {
            throw InvalidTransition(fromState: state, action: action)
        }

        if let toState = transition.toState {
            state = toState
        }

        if let sideEffect = transition.sideEffect {
            try sideEffect.execute(in: self)
        }
    }

    func addObserver(_ observer: ExperienceStateObserver) {
        stateObservers.append(observer)
    }
}

// MARK: - ExperienceContainerLifecycleHandler

@available(iOS 13.0, *)
extension ExperienceStateMachine: ExperienceContainerLifecycleHandler {
    // MARK: Step Lifecycle

    func containerWillAppear() {
        switch state {
        case let .beginningStep(_, _, package, isFirst) where isFirst && package.wrapperController.isBeingPresented:
            experienceWillAppear()
        default:
            break
        }
    }

    func containerDidAppear() {
        switch state {
        case let .beginningStep(_, _, package, isFirst) where isFirst && package.wrapperController.isBeingPresented:
            experienceDidAppear()
        default:
            break
        }
    }

    func containerWillDisappear() {
        switch state {
        case .endingExperience:
            experienceWillDisappear()
        case let .renderingStep(_, _, package, _) where package.wrapperController.isBeingDismissed:
            experienceWillDisappear()
        default:
            break
        }
    }

    func containerDidDisappear() {
        switch state {
        case .endingExperience:
            experienceDidDisappear()
        case let .renderingStep(_, _, package, _) where package.wrapperController.isBeingDismissed:
            experienceDidDisappear()
            // Update state in response to UI changes that have happened already (a call to UIViewController.dismiss).
            try? transition(.endExperience(markComplete: false))
        default:
            break
        }
    }

    func containerNavigated(from oldPageIndex: Int, to newPageIndex: Int) {
        // Set state directly in response to UI changes that have happened already
        switch state {
        case let .renderingStep(experience, stepIndex, package, _):
            let targetStepId = package.steps[newPageIndex].id
            if let newStepIndex = experience.stepIndex(for: targetStepId) {
                state = .endingStep(experience, stepIndex, package, markComplete: newPageIndex > oldPageIndex)
                state = .beginningStep(experience, stepIndex, package, isFirst: false)
                state = .renderingStep(experience, newStepIndex, package, isFirst: false)
            }
        case let .endingStep(experience, _, package, _):
            let targetStepId = package.steps[newPageIndex].id
            if let newStepIndex = experience.stepIndex(for: targetStepId) {
                state = .beginningStep(experience, newStepIndex, package, isFirst: false)
                state = .renderingStep(experience, newStepIndex, package, isFirst: false)
            }
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

// MARK: - State Machine Types

@available(iOS 13.0, *)
extension ExperienceStateMachine {
    struct Transition {
        let toState: State?
        let sideEffect: SideEffect?

        init(toState: State?, sideEffect: SideEffect? = nil) {
            self.toState = toState
            self.sideEffect = sideEffect
        }
    }

    struct InvalidTransition: Error {
        let fromState: State
        let action: Action
    }
}

@available(iOS 13.0, *)
extension ExperienceStateMachine {
    enum SideEffect {
        case continuation(Action)
        case presentContainer(ExperienceData, Experience.StepIndex, ExperiencePackage, [Experience.Action])
        case navigateInContainer(ExperiencePackage, pageIndex: Int)
        case dismissContainer(ExperiencePackage, continuation: Action)
        case error(ExperienceError, reset: Bool)
        case processActions([ExperienceAction])

        func execute(in machine: ExperienceStateMachine) throws {
            switch self {
            case .continuation(let action):
                try machine.transition(action)
            case let .presentContainer(experience, stepIndex, package, actions):
                machine.actionRegistry.enqueue(actionModels: actions) {
                    executePresentContainer(
                        machine: machine,
                        experience: experience,
                        stepIndex: stepIndex,
                        package: package
                    )
                }
            case let .navigateInContainer(package, pageIndex):
                package.containerController.navigate(to: pageIndex, animated: true)
            case let .dismissContainer(package, action):
                package.dismisser { try? machine.transition(action) }
            case let .error(error, reset):
                // Call each observer with the error as a failure and filter out ones that been satisfied
                machine.stateObservers = machine.stateObservers.filter {
                    !$0.evaluateIfSatisfied(result: .failure(error))
                }
                if reset {
                    machine.state = .idling
                }
            case let .processActions(actions):
                machine.actionRegistry.enqueue(actionInstances: actions)
            }
        }

        private func executePresentContainer(
            machine: ExperienceStateMachine,
            experience: ExperienceData,
            stepIndex: Experience.StepIndex,
            package: ExperiencePackage
        ) {
            machine.clientControllerDelegate = UIApplication.shared.topViewController() as? AppcuesExperienceDelegate
            guard machine.canDisplay(experience: experience.model) else {
                try? machine.transition(.reportError(.step(experience, stepIndex, "Step blocked by app"), fatal: true))
                return
            }

            package.containerController.lifecycleHandler = machine

            package.pageMonitor.addObserver { [weak machine, weak package] newIndex, oldIndex in
                do {
                    try package?.stepDecoratingTraitUpdater(newIndex, oldIndex)
                    machine?.containerNavigated(from: oldIndex, to: newIndex)
                } catch {
                    // Report a fatal error and dismiss the experience
                    let errorTargetStepIndex = Experience.StepIndex(group: stepIndex.group, item: newIndex)
                    try? machine?.transition(.reportError(.step(experience, errorTargetStepIndex, "\(error)"), fatal: true))
                    package?.dismisser({})
                }
            }

            // This flag tells automatic screen tracking to ignore screens that the SDK is presenting
            objc_setAssociatedObject(package.wrapperController, &UIKitScreenTracker.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

            // The dispatcher call here with asyncAfter is to attempt to let any pending layout operations complete
            // before running this new container presentation. The package.stepDecoratingTraitUpdater in particular may
            // be looking for target elements on the view that need to be fully loaded first, and this container
            // may be presenting after a pre-step navigation action that is finalizing the loading of the new view.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                do {
                    try package.stepDecoratingTraitUpdater(stepIndex.item, nil)
                    SdkMetrics.renderStart(experience.requestID)
                    try package.presenter {
                        try? machine.transition(.renderStep)
                    }
                } catch {
                    try? machine.transition(.reportError(.step(experience, stepIndex, "\(error)"), fatal: true))
                }
            }
        }
    }
}
