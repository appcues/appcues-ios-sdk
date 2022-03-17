//
//  ExperienceStateMachine.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-19.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class ExperienceStateMachine {

    private let config: Appcues.Config
    private let traitComposer: TraitComposing
    private let storage: DataStoring

    private var stateObservers: [ExperienceStateObserver] = []

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

    init(container: DIContainer) {
        config = container.resolve(Appcues.Config.self)
        traitComposer = container.resolve(TraitComposing.self)
        storage = container.resolve(DataStoring.self)

        state = .idling
    }

    /// Transition to a new state.
    /// - Parameters:
    ///   - newState: `ExperienceState` to attempt a transition to.
    ///   - observer: Block that's called on each state change, or if no state change occurs (represented by a `nil` value).
    ///   Must return `true` iff the observer is complete and should be removed.
    func transitionAndObserve(_ action: Action, observer: @escaping (ExperienceStateObserver.StateResult) -> Bool) {
        let observer = StateObserver(observer)
        stateObservers.append(observer)

        do {
            try transition(action)
        } catch {
            let observerIsSatisfiedByFailure = observer.evaluateIfSatisfied(result: .failure(ExperienceError.noTransition))
            if observerIsSatisfiedByFailure {
                stateObservers = stateObservers.filter { $0 !== observer }
            }
        }
    }

    @discardableResult
    func transition(_ action: Action) throws -> Output {
        guard let transition = state.transition(for: action, traitComposer: traitComposer) else {
            throw InvalidTransition(fromState: state, action: action)
        }

        if let toState = transition.toState {
            state = toState
        }

        if let sideEffect = transition.sideEffect {
            if let newStateOutput = try sideEffect.execute(in: self) {
                return newStateOutput
            }
        }

        return Output(fromState: state, action: action, toState: transition.toState ?? state, sideEffect: transition.sideEffect)
    }

    func addObserver(_ observer: ExperienceStateObserver) {
        stateObservers.append(observer)
    }
}

// MARK: - ExperienceContainerLifecycleHandler

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
        case let .renderingStep(_, _, package) where package.wrapperController.isBeingDismissed:
            experienceWillDisappear()
        default:
            break
        }
    }

    func containerDidDisappear() {
        switch state {
        case .endingExperience:
            experienceDidDisappear()
        case let .renderingStep(_, _, package) where package.wrapperController.isBeingDismissed:
            experienceDidDisappear()
            // Update state in response to UI changes that have happened already (a call to UIViewController.dismiss).
            _ = try? transition(.endExperience)
        default:
            break
        }
    }

    func containerNavigated(from oldPageIndex: Int, to newPageIndex: Int) {
        // Set state directly in response to UI changes that have happened already
        switch state {
        case let .renderingStep(experience, stepIndex, package):
            let targetStepId = package.steps[newPageIndex].id
            if let newStepIndex = experience.stepIndex(for: targetStepId) {
                state = .endingStep(experience, stepIndex, package)
                state = .beginningStep(experience, stepIndex, package, isFirst: false)
                state = .renderingStep(experience, newStepIndex, package)
            }
        case let .endingStep(experience, _, package):
            let targetStepId = package.steps[newPageIndex].id
            if let newStepIndex = experience.stepIndex(for: targetStepId) {
                state = .beginningStep(experience, newStepIndex, package, isFirst: false)
                state = .renderingStep(experience, newStepIndex, package)
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

extension ExperienceStateMachine {
    struct Output: Equatable {
        let fromState: State
        let action: Action
        let toState: State
        let sideEffect: SideEffect?
    }

    struct Transition {
        let toState: State?
        let sideEffect: SideEffect?

        init(toState: State?, sideEffect: SideEffect? = nil) {
            self.toState = toState
            self.sideEffect = sideEffect
        }
    }

    struct InvalidTransition: Error, Equatable {
        let fromState: State
        let action: Action
    }
}

extension ExperienceStateMachine {
    enum SideEffect {
        case continuation(Action)
        case presentContainer(Experience, Experience.StepIndex, ExperiencePackage)
        case navigateInContainer(ExperiencePackage, pageIndex: Int)
        case dismissContainer(ExperiencePackage, continuation: Action)
        case error(ExperienceError)

        func execute(in machine: ExperienceStateMachine) throws -> Output? {
            switch self {
            case .continuation(let action):
                return try machine.transition(action)
            case let .presentContainer(experience, stepIndex, package):
                executePresentContainer(machine: machine, experience: experience, stepIndex: stepIndex, package: package)
            case let .navigateInContainer(package, pageIndex):
                package.containerController.navigate(to: pageIndex, animated: true)
            case let .dismissContainer(package, action):
                package.dismisser { _ = try? machine.transition(action) }
            case let .error(error):
                // Call each observer with the error as a failure and filter out ones that been satisfied
                machine.stateObservers = machine.stateObservers.filter {
                    !$0.evaluateIfSatisfied(result: .failure(error))
                }
            }

            return nil
        }

        private func executePresentContainer(
            machine: ExperienceStateMachine, experience: Experience, stepIndex: Experience.StepIndex, package: ExperiencePackage
        ) {
            if let topController = UIApplication.shared.topViewController() {
                machine.clientControllerDelegate = topController as? AppcuesExperienceDelegate
                if !machine.canDisplay(experience: experience) {
                    _ = try? machine.transition(.error(.step(experience, stepIndex, "Step blocked by app")))
                    return
                }
            }

            package.containerController.lifecycleHandler = machine

            // This flag tells automatic screen tracking to ignore screens that the SDK is presenting
            objc_setAssociatedObject(package.wrapperController, &UIKitScreenTracker.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

            do {
                try package.presenter {
                    _ = try? machine.transition(.renderStep)
                }

                machine.storage.lastContentShownAt = Date()
            } catch {
                _ = try? machine.transition(.error(.step(experience, stepIndex, "\(error)")))
            }
        }
    }
}

extension ExperienceStateMachine.SideEffect: Equatable {
    static func == (lhs: ExperienceStateMachine.SideEffect, rhs: ExperienceStateMachine.SideEffect) -> Bool {
        switch (lhs, rhs) {
        case let (.continuation(action1), .continuation(action2)):
            return action1 == action2
        case let (.presentContainer(experience1, stepIndex1, _), .presentContainer(experience2, stepIndex2, _)):
            return experience1.id == experience2.id && stepIndex1 == stepIndex2
        case let (.navigateInContainer(_, pageIndex1), .navigateInContainer(_, pageIndex2)):
            return pageIndex1 == pageIndex2
        case let (.dismissContainer(_, action1), .dismissContainer(_, action2)):
            return action1 == action2
        default:
            return false
        }
    }
}
