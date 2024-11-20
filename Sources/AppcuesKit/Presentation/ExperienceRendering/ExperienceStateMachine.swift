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
    private let actionRegistry: ActionRegistry

    private(set) var stateObservers: [ExperienceStateObserver] = []

    private(set) var state: State {
        didSet {
            // Call each observer and filter out ones that been satisfied
            stateObservers = stateObservers.filter { !$0.evaluateIfSatisfied(result: .success(state)) }
        }
    }

    weak var clientAppcuesPresentationDelegate: AppcuesPresentationDelegate?
    weak var clientControllerPresentationDelegate: AppcuesPresentationDelegate?

    weak var clientAppcuesDelegate: AppcuesExperienceDelegate?
    weak var clientControllerDelegate: AppcuesExperienceDelegate?

    init(container: DIContainer, initialState: State = .idling) {
        config = container.resolve(Appcues.Config.self)
        traitComposer = container.resolve(TraitComposing.self)
        actionRegistry = container.resolve(ActionRegistry.self)

        state = initialState
    }

    func transition(_ action: Action) async throws {
        guard let transition = await state.transition(for: action, traitComposer: traitComposer) else {
            throw InvalidTransition(fromState: state, action: action)
        }

        // needs to happen even if the side effect throws
        defer {
            // only after the rest of the transition has fully completed, check if we should
            // remove all the observers (i.e. clear the analytics observer on return to idling)
            if transition.resetObservers {
                stateObservers.removeAll()
            }
        }

        if let toState = transition.toState {
            state = toState
        }

        if let sideEffect = transition.sideEffect {
            try await sideEffect.execute(in: self)
        }
    }

    func addObserver(_ observer: ExperienceStateObserver) {
        stateObservers.append(observer)
    }

    func removeAnalyticsObserver() {
        stateObservers = stateObservers.filter { !($0 is AnalyticsObserver) }
    }

    func handlePresentationError(
        _ error: Error,
        experience: ExperienceData,
        stepIndex: Experience.StepIndex,
        package: ExperiencePackage
    ) async {
        let recoverable = (error as? AppcuesTraitError)?.recoverable ?? false
        let retryEffect: ExperienceStateMachine.SideEffect? = recoverable ? .retryPresentation(experience, stepIndex, package) : nil
        try? await transition(
            .reportError(
                error: .step(experience, stepIndex, "\(error)", recoverable: recoverable),
                retryEffect: retryEffect
            )
        )
    }
}

// MARK: - AppcuesExperienceContainerEventHandler

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
        case let .beginningStep(experience, _, package, isFirst) where package.wrapperController.isAppearing:
            if isFirst {
                experienceDidAppear(experience: experience)
            } else {
                experienceStepDidChange(experience: experience)
            }
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
            Task {
                try? await transition(.endExperience(markComplete: false))
            }
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
            experienceStepDidChange(experience: experience)
        case let .endingStep(experience, _, package, _):
            let targetStepId = package.steps[newPageIndex].id
            if let newStepIndex = experience.stepIndex(for: targetStepId) {
                state = .beginningStep(experience, newStepIndex, package, isFirst: false)
                state = .renderingStep(experience, newStepIndex, package, isFirst: false)
            }
            experienceStepDidChange(experience: experience)
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

        if let delegate = clientControllerPresentationDelegate, !delegate.canDisplayExperience(metadata: experience.delegateMetadata()) {
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
        clientControllerPresentationDelegate?.experienceWillAppear(metadata: experience.delegateMetadata())
        clientAppcuesPresentationDelegate?.experienceWillAppear(metadata: experience.delegateMetadata())
    }

    private func experienceDidAppear(experience: ExperienceData) {
        clientControllerDelegate?.experienceDidAppear()
        clientAppcuesDelegate?.experienceDidAppear()
        clientControllerPresentationDelegate?.experienceDidAppear(metadata: experience.delegateMetadata())
        clientAppcuesPresentationDelegate?.experienceDidAppear(metadata: experience.delegateMetadata())
    }

    private func experienceStepDidChange(experience: ExperienceData) {
        clientControllerPresentationDelegate?.experienceStepDidChange(metadata: experience.delegateMetadata())
        clientAppcuesPresentationDelegate?.experienceStepDidChange(metadata: experience.delegateMetadata())
    }

    private func experienceWillDisappear(experience: ExperienceData) {
        clientControllerDelegate?.experienceWillDisappear()
        clientAppcuesDelegate?.experienceWillDisappear()
        clientControllerPresentationDelegate?.experienceWillDisappear(metadata: experience.delegateMetadata())
        clientAppcuesPresentationDelegate?.experienceWillDisappear(metadata: experience.delegateMetadata())
    }

    private func experienceDidDisappear(experience: ExperienceData) {
        clientControllerDelegate?.experienceDidDisappear()
        clientAppcuesDelegate?.experienceDidDisappear()
        clientControllerPresentationDelegate?.experienceDidDisappear(metadata: experience.delegateMetadata())
        clientAppcuesPresentationDelegate?.experienceDidDisappear(metadata: experience.delegateMetadata())
    }
}

private extension UIViewController {
    var isAppearing: Bool { isBeingPresented || isMovingToParent }
    var isDisappearing: Bool { isBeingDismissed || isMovingFromParent }
}

// MARK: - State Machine Types

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

extension ExperienceStateMachine {
    enum SideEffect {
        case continuation(Action)
        case presentContainer(ExperienceData, Experience.StepIndex, ExperiencePackage, [Experience.Action])
        case retryPresentation(ExperienceData, Experience.StepIndex, ExperiencePackage)
        case navigateInContainer(ExperiencePackage, pageIndex: Int)
        case dismissContainer(ExperiencePackage, continuation: Action)
        case error(ExperienceError)
        case processActions((Appcues?) -> [AppcuesExperienceAction])

        func execute(in machine: ExperienceStateMachine) async throws {
            switch self {
            case .continuation(let action):
                try await machine.transition(action)
            case let .presentContainer(experience, stepIndex, package, actions):
                try? await machine.actionRegistry.enqueue(actionModels: actions, level: .group, renderContext: experience.renderContext)
                await executePresentContainer(
                    machine: machine,
                    experience: experience,
                    stepIndex: stepIndex,
                    package: package,
                    isRecovering: false
                )
            case let .retryPresentation(experience, stepIndex, package):
                await executePresentContainer(
                    machine: machine,
                    experience: experience,
                    stepIndex: stepIndex,
                    package: package,
                    isRecovering: true
                )
            case let .navigateInContainer(package, pageIndex):
                await package.containerController.navigate(to: pageIndex, animated: true)
            case let .dismissContainer(package, action):
                await package.dismisser()
                try? await machine.transition(action)
            case let .error(error):
                // Call each observer with the error as a failure and filter out ones that been satisfied
                machine.stateObservers = machine.stateObservers.filter {
                    !$0.evaluateIfSatisfied(result: .failure(error))
                }
                throw error
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
        ) async {
            machine.clientControllerDelegate = await UIApplication.shared.topViewController() as? AppcuesExperienceDelegate
            guard machine.canDisplay(experience: experience) else {
                try? await machine.transition(
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
                    Task {
                        do {
                            try await package.stepDecoratingTraitUpdater(newIndex, oldIndex)
                            machine.containerNavigated(from: oldIndex, to: newIndex)
                        } catch {
                            // Report a fatal error and dismiss the experience
                            let errorIndex = Experience.StepIndex(group: stepIndex.group, item: newIndex)
                            await machine.handlePresentationError(error, experience: experience, stepIndex: errorIndex, package: package)
                            await package.dismisser()
                        }
                    }
                }
            }

            // This flag tells automatic screen tracking to ignore screens that the SDK is presenting
            objc_setAssociatedObject(package.wrapperController, &UIKitScreenTracker.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

            func presentStep() async throws {
                do {
                    try await package.stepDecoratingTraitUpdater(stepIndex.item, nil)
                    try await package.presenter()
                    try await machine.transition(.renderStep)
                } catch {
                    if let error = error as? AppcuesTraitError,
                       let retryMilliseconds = error.retryMilliseconds {
                        try await Task.sleep(nanoseconds: UInt64(retryMilliseconds * 1_000_000))
                        try await presentStep()
                    } else {
                        throw error
                    }
                }
            }

            // Rendering metrics start now, and will include any time spent in error/retry of trait application
            // inside of the presentStep local helper function.
            SdkMetrics.renderStart(experience.requestID)

            do {
                try await presentStep()
            } catch {
                await machine.handlePresentationError(error, experience: experience, stepIndex: stepIndex, package: package)
            }
        }
    }
}
