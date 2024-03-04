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
        }
    }

    weak var clientAppcuesPresentationDelegate: AppcuesPresentationDelegate?

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

        // only after the rest of the transition has fully completed, check if we should
        // remove all the observers (i.e. clear the analytics observer on return to idling)
        if transition.resetObservers {
            stateObservers.removeAll()
        }
    }

    func addObserver(_ observer: ExperienceStateObserver) {
        stateObservers.append(observer)
    }

    func removeAnalyticsObserver() {
        stateObservers = stateObservers.filter { !($0 is AnalyticsObserver) }
    }
}

// MARK: - AppcuesExperienceContainerEventHandler

@available(iOS 13.0, *)
extension ExperienceStateMachine: AppcuesExperienceContainerEventHandler {
    // MARK: Step Lifecycle

    func containerWillAppear() {
        switch state {
        case let .beginningStep(experience, _, package, isFirst) where isFirst && package.wrapperController.isAppearing:
            experienceWillAppear(experience: experience)
        default:
            break
        }
    }

    func containerDidAppear() {
        switch state {
        case let .beginningStep(experience, _, package, isFirst) where isFirst && package.wrapperController.isAppearing:
            experienceDidAppear(experience: experience)
        default:
            break
        }
    }

    func containerWillDisappear() {
        switch state {
        case let .endingExperience(experience, _, _):
            experienceWillDisappear(experience: experience)
        case let .renderingStep(experience, _, package, _) where package.wrapperController.isDisappearing:
            experienceWillDisappear(experience: experience)
        default:
            break
        }
    }

    func containerDidDisappear() {
        switch state {
        case let .endingExperience(experience, _, _):
            experienceDidDisappear(experience: experience)
        case let .renderingStep(experience, _, package, _) where package.wrapperController.isDisappearing:
            experienceDidDisappear(experience: experience)
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

    func canDisplay(experience: ExperienceData) -> Bool {
        let id = experience.id.uuidString

        if let delegate = clientControllerDelegate, !delegate.canDisplayExperience(experienceID: id) {
            return false
        }

        if let delegate = clientAppcuesDelegate, !delegate.canDisplayExperience(experienceID: id) {
            return false
        }

        if let delegate = clientAppcuesPresentationDelegate, !delegate.canDisplayExperience(metadata: experience.delegateMetadata()) {
            return false
        }

        return true
    }

    private func experienceWillAppear(experience: ExperienceData) {
        clientControllerDelegate?.experienceWillAppear()
        clientAppcuesDelegate?.experienceWillAppear()
        clientAppcuesPresentationDelegate?.experienceWillAppear(metadata: experience.delegateMetadata())
    }

    private func experienceDidAppear(experience: ExperienceData) {
        clientControllerDelegate?.experienceDidAppear()
        clientAppcuesDelegate?.experienceDidAppear()
        clientAppcuesPresentationDelegate?.experienceDidAppear(metadata: experience.delegateMetadata())
    }

    private func experienceWillDisappear(experience: ExperienceData) {
        clientControllerDelegate?.experienceWillDisappear()
        clientAppcuesDelegate?.experienceWillDisappear()
        clientAppcuesPresentationDelegate?.experienceWillDisappear(metadata: experience.delegateMetadata())
    }

    private func experienceDidDisappear(experience: ExperienceData) {
        clientControllerDelegate?.experienceDidDisappear()
        clientAppcuesDelegate?.experienceDidDisappear()
        clientAppcuesPresentationDelegate?.experienceDidDisappear(metadata: experience.delegateMetadata())
    }
}

private extension UIViewController {
    var isAppearing: Bool { isBeingPresented || isMovingToParent }
    var isDisappearing: Bool { isBeingDismissed || isMovingFromParent }
}

// MARK: - State Machine Types

@available(iOS 13.0, *)
extension ExperienceStateMachine {
    struct Transition {
        let toState: State?
        let sideEffect: SideEffect?
        let resetObservers: Bool

        init(toState: State?, sideEffect: SideEffect? = nil, resetObservers: Bool = false) {
            self.toState = toState
            self.sideEffect = sideEffect
            self.resetObservers = resetObservers
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
        case retryPresentation(ExperienceData, Experience.StepIndex, ExperiencePackage)
        case navigateInContainer(ExperiencePackage, pageIndex: Int)
        case dismissContainer(ExperiencePackage, continuation: Action)
        case error(ExperienceError)
        case processActions((Appcues?) -> [AppcuesExperienceAction])

        func execute(in machine: ExperienceStateMachine) throws {
            switch self {
            case .continuation(let action):
                try machine.transition(action)
            case let .presentContainer(experience, stepIndex, package, actions):
                machine.actionRegistry.enqueue(actionModels: actions, level: .group, renderContext: experience.renderContext) {
                    executePresentContainer(
                        machine: machine,
                        experience: experience,
                        stepIndex: stepIndex,
                        package: package,
                        isRecovering: false
                    )
                }
            case let .retryPresentation(experience, stepIndex, package):
                executePresentContainer(
                    machine: machine,
                    experience: experience,
                    stepIndex: stepIndex,
                    package: package,
                    isRecovering: true
                )
            case let .navigateInContainer(package, pageIndex):
                package.containerController.navigate(to: pageIndex, animated: true)
            case let .dismissContainer(package, action):
                package.dismisser { try? machine.transition(action) }
            case let .error(error):
                // Call each observer with the error as a failure and filter out ones that been satisfied
                machine.stateObservers = machine.stateObservers.filter {
                    !$0.evaluateIfSatisfied(result: .failure(error))
                }
            case let .processActions(actionFactory):
                machine.actionRegistry.enqueue(actionFactory: actionFactory)
            }
        }

        private func executePresentContainer(
            machine: ExperienceStateMachine,
            experience: ExperienceData,
            stepIndex: Experience.StepIndex,
            package: ExperiencePackage,
            isRecovering: Bool
        ) {
            machine.clientControllerDelegate = UIApplication.shared.topViewController() as? AppcuesExperienceDelegate
            guard machine.canDisplay(experience: experience) else {
                try? machine.transition(
                    .reportError(
                        error: .step(experience, stepIndex, "Step blocked by app"),
                        retryEffect: nil
                    )
                )
                return
            }

            package.containerController.eventHandler = machine

            if !isRecovering { // guard against adding multiple observers during recovery attempts
                package.pageMonitor.addObserver { [weak machine, weak package] newIndex, oldIndex in
                    guard let machine = machine, let package = package else { return }
                    do {
                        try package.stepDecoratingTraitUpdater(newIndex, oldIndex)
                        machine.containerNavigated(from: oldIndex, to: newIndex)
                    } catch {
                        // Report a fatal error and dismiss the experience
                        let errorIndex = Experience.StepIndex(group: stepIndex.group, item: newIndex)
                        handlePresentationError(error, machine: machine, experience: experience, stepIndex: errorIndex, package: package)
                        package.dismisser({})
                    }
                }
            }

            // This flag tells automatic screen tracking to ignore screens that the SDK is presenting
            objc_setAssociatedObject(package.wrapperController, &UIKitScreenTracker.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

            // The dispatcher call here with asyncAfter is to attempt to let any pending layout operations complete
            // before running this new container presentation. The package.stepDecoratingTraitUpdater in particular may
            // be looking for target elements on the view that need to be fully loaded first, and this container
            // may be presenting after a pre-step navigation action that is finalizing the loading of the new view.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {

                func presentStep(onError: @escaping (Error) -> Void) {
                    do {
                        try package.stepDecoratingTraitUpdater(stepIndex.item, nil)
                        try package.presenter {
                            try? machine.transition(.renderStep)
                        }
                    } catch {
                        if let error = error as? AppcuesTraitError,
                           let retryMilliseconds = error.retryMilliseconds {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(retryMilliseconds)) {
                                presentStep(onError: onError)
                            }
                        } else {
                            onError(error)
                        }
                    }
                }

                // Rendering metrics start now, and will include any time spent in error/retry of trait application
                // inside of the presentStep local helper function.
                SdkMetrics.renderStart(experience.requestID)

                presentStep { error in
                    handlePresentationError(error, machine: machine, experience: experience, stepIndex: stepIndex, package: package)
                }
            }
        }

        private func handlePresentationError(
            _ error: Error,
            machine: ExperienceStateMachine,
            experience: ExperienceData,
            stepIndex: Experience.StepIndex,
            package: ExperiencePackage
        ) {
            let recoverable = (error as? AppcuesTraitError)?.recoverable ?? false
            let retryEffect: ExperienceStateMachine.SideEffect? = recoverable ? .retryPresentation(experience, stepIndex, package) : nil
            try? machine.transition(
                .reportError(
                    error: .step(experience, stepIndex, "\(error)", recoverable: recoverable),
                    retryEffect: retryEffect
                )
            )
        }
    }
}
