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

        state = initialState
    }

    /// Transition to a new state.
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
            let observerIsSatisfiedByFailure = observer.evaluateIfSatisfied(result: .failure(ExperienceError.noTransition))
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
            _ = try? transition(.endExperience(markComplete: false))
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
                state = .endingStep(experience, stepIndex, package)
                state = .beginningStep(experience, stepIndex, package, isFirst: false)
                state = .renderingStep(experience, newStepIndex, package, isFirst: false)
            }
        case let .endingStep(experience, _, package):
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
        case presentContainer(Experience, Experience.StepIndex, ExperiencePackage)
        case navigateInContainer(ExperiencePackage, pageIndex: Int)
        case dismissContainer(ExperiencePackage, continuation: Action)
        case error(ExperienceError, reset: Bool)

        func execute(in machine: ExperienceStateMachine) throws {
            switch self {
            case .continuation(let action):
                try machine.transition(action)
            case let .presentContainer(experience, stepIndex, package):
                executePresentContainer(machine: machine, experience: experience, stepIndex: stepIndex, package: package)
            case let .navigateInContainer(package, pageIndex):
                package.containerController.navigate(to: pageIndex, animated: true)
            case let .dismissContainer(package, action):
                package.dismisser { _ = try? machine.transition(action) }
            case let .error(error, reset):
                // Call each observer with the error as a failure and filter out ones that been satisfied
                machine.stateObservers = machine.stateObservers.filter {
                    !$0.evaluateIfSatisfied(result: .failure(error))
                }
                if reset {
                    machine.state = .idling
                }
            }
        }

        private func executePresentContainer(
            machine: ExperienceStateMachine, experience: Experience, stepIndex: Experience.StepIndex, package: ExperiencePackage
        ) {
            machine.clientControllerDelegate = UIApplication.shared.topViewController() as? AppcuesExperienceDelegate
            if !machine.canDisplay(experience: experience) {
                _ = try? machine.transition(.reportError(.step(experience, stepIndex, "Step blocked by app"), fatal: true))
                return
            }

            package.containerController.lifecycleHandler = machine

            // This flag tells automatic screen tracking to ignore screens that the SDK is presenting
            objc_setAssociatedObject(package.wrapperController, &UIKitScreenTracker.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

            do {
                try package.presenter {
                    _ = try? machine.transition(.renderStep)
                }
            } catch {
                _ = try? machine.transition(.reportError(.step(experience, stepIndex, "\(error)"), fatal: true))
            }
        }
    }
}
