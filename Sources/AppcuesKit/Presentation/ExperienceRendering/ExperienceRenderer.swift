//
//  ExperienceRenderer.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-20.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal protocol ExperienceRendering: AnyObject {
    func start(owner: StateMachineOwning, forContext context: RenderContext)
    func processAndShow(qualifiedExperiences: [ExperienceData], reason: ExperienceTrigger)
    func processAndShow(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?)
    func show(step stepRef: StepReference, inContext context: RenderContext, completion: (() -> Void)?)
    func dismiss(inContext context: RenderContext, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func experienceData(forContext context: RenderContext) -> ExperienceData?
    func stepIndex(forContext context: RenderContext) -> Experience.StepIndex?
    func owner(forContext context: RenderContext) -> StateMachineOwning?
    func resetAll()
}

internal enum RenderContext: Hashable, CustomStringConvertible {
    case modal
    case embed(frameID: String)

    var description: String {
        switch self {
        case .modal:
            return "modal"
        case .embed(let frameID):
            return "frame \(frameID)"
        }
    }
}

internal enum ExperienceRendererError: Error {
    case renderDeferred(RenderContext, Experience)
    case noStateMachine
    case experimentControl
}

@available(iOS 13.0, *)
private class StepRecoveryObserver: ExperienceStateObserver {
    private let stateMachine: ExperienceStateMachine

    // private var retryWorkItem: DispatchWorkItem?

    init(stateMachine: ExperienceStateMachine) {
        self.stateMachine = stateMachine
    }

    func stopRetryHandler() {
//        if retryWorkItem != nil {
//            print("stopping existing step recovery attempts due to screen change")
//        }
//        retryWorkItem?.cancel()
//        retryWorkItem = nil
    }

    func evaluateIfSatisfied(result: ExperienceStateObserver.StateResult) -> Bool {
        if case .failure(.step(_, _, _, recoverable: true)) = result {
            // startRetryHandler()
        }

        // recovery observer never stops observing
        return false
    }

    private func startRetryHandler() {
        // this is where we would inject more advanced logic - we'll want to start observing
        // scroll changes and detect when they occur and then come to rest, with some debounce,
        // then trigger a retry

        // simulating this with a 3 sec timer to test for now

//        if retryWorkItem == nil {
//            print("recoverable step error - will retry in 3 sec")
//            let workItem = DispatchWorkItem { [weak self] in
//                guard let self = self else { return }
//                print("retrying step...")
//                self.retryWorkItem = nil
//                try? self.stateMachine.transition(.retry)
//            }
//            retryWorkItem = workItem
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
//        }
    }
}

@available(iOS 13.0, *)
internal class ExperienceRenderer: ExperienceRendering, StateMachineOwning {

    // Conformance to `StateMachineOwning`.
    /// State machine for `RenderContext.modal`
    var stateMachine: ExperienceStateMachine?
    var renderContext: RenderContext?

    private var stateMachines = StateMachineDirectory()
    private var pendingPreviewExperiences: [RenderContext: ExperienceData] = [:]
    private var potentiallyRenderableExperiences: [RenderContext: [ExperienceData]] = [:]
    private let analyticsObserver: ExperienceStateMachine.AnalyticsObserver
    private let stepRecoveryObserver: StepRecoveryObserver
    private weak var appcues: Appcues?
    private let config: Appcues.Config

    init(container: DIContainer) {
        self.appcues = container.owner
        self.config = container.resolve(Appcues.Config.self)

        // two items below are not registered/resolved directly from container as they
        // are considered private implementation details of the ExperienceRenderer - helpers.
        let stateMachine = ExperienceStateMachine(container: container)
        self.stateMachine = stateMachine
        self.analyticsObserver = ExperienceStateMachine.AnalyticsObserver(container: container)
        self.stepRecoveryObserver = StepRecoveryObserver(stateMachine: stateMachine)

        stateMachines[ownerFor: .modal] = self
    }

    func start(owner: StateMachineOwning, forContext context: RenderContext) {
        guard let container = appcues?.container else { return }

        // If there's already a frame for the context, reset it back to its unregistered state.
        if let existingFrameView = stateMachines[ownerFor: context] as? AppcuesFrameView {
            existingFrameView.reset()
        }

        // If the machine being started is already registered for a different context,
        // reset it back to its unregistered state before potentially showing new content.
        if owner.stateMachine != nil, let frameView = owner as? AppcuesFrameView {
            frameView.reset()
        }

        owner.stateMachine = ExperienceStateMachine(container: container)
        stateMachines[ownerFor: context] = owner
        // A preview experience takes priority over qualified experiences.
        if let pendingPreviewExperience = pendingPreviewExperiences[context] {
            show(experience: pendingPreviewExperience, completion: nil)
        } else if let pendingExperiences = potentiallyRenderableExperiences[context] {
            show(qualifiedExperiences: pendingExperiences, completion: nil)
        }
    }

    func processAndShow(qualifiedExperiences: [ExperienceData], reason: ExperienceTrigger) {
        let shouldClearCache = reason == .qualification(reason: .screenView)
        if shouldClearCache {
            potentiallyRenderableExperiences = [:]
            stateMachines.cleanup()
            stepRecoveryObserver.stopRetryHandler()
        }

        // Add new experiences, replacing any existing ones
        let grouped = Dictionary(grouping: qualifiedExperiences) { $0.renderContext }
        potentiallyRenderableExperiences = potentiallyRenderableExperiences.merging(grouped)

        potentiallyRenderableExperiences.forEach { _, qualifiedExperiences in
            show(qualifiedExperiences: qualifiedExperiences, completion: nil)
        }

        // No caching required for modals since they can't be lazy-loaded.
        potentiallyRenderableExperiences.removeValue(forKey: .modal)
    }

    func processAndShow(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?) {
        let reason = experience.trigger

        if reason == .preview {
            pendingPreviewExperiences[experience.renderContext] = experience
        } else if experience.renderContext != .modal {
            // No caching required for modals since they can't be lazy-loaded.
            potentiallyRenderableExperiences[experience.renderContext] = [experience]
        }

        show(experience: experience, completion: completion)
    }

    private func show(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(experience: experience, completion: completion)
            }
            return
        }

        guard let stateMachine = stateMachines[experience.renderContext] else {
            analyticsObserver.trackRecoverableError(
                experience: experience,
                message: "no render context for \(experience.renderContext.description)"
            )
            completion?(.failure(ExperienceRendererError.renderDeferred(experience.renderContext, experience.model)))
            return
        }

        guard experience.instanceID != stateMachine.state.currentExperienceData?.instanceID else {
            // This experience is already showing
            completion?(.success(()))
            return
        }

        guard experience.experiment?.shouldExecute ?? true else {
            // if we get here, it means we did have an experiment, but it was the control group and
            // we should not continue. So track experiment_entered analytics for it (always)..
            track(experiment: experience.experiment)
            // and exit early
            completion?(.failure(ExperienceRendererError.experimentControl))
            return
        }

        if experience.priority == .normal && stateMachine.state != .idling {
            dismiss(inContext: experience.renderContext, markComplete: false) { result in
                switch result {
                case .success:
                    self.show(experience: experience, completion: completion)
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            return
        }

        // all the pre-requisite checks are complete - start the experience
        start(experience, in: stateMachine, completion: completion)
    }

    private func start(
        _ experience: ExperienceData,
        in stateMachine: ExperienceStateMachine,
        completion: ((Result<Void, Error>) -> Void)?
    ) {
        // if we get here, either we did not have an experiment, or it is active and did not exit early (not control group).
        // if an active experiment does exist, it should now track the experiment_entered analytic
        track(experiment: experience.experiment)

        // only track analytics on published experiences (not previews)
        // and only add the observer if the state machine is idling, otherwise there's already another experience in-flight
        if stateMachine.state == .idling {
            if experience.published {
                stateMachine.addObserver(analyticsObserver)
            }

            if experience.renderContext == .modal {
                // add recovery observer - on recoverable step errors, initiate recovery and retry
                stateMachine.addObserver(stepRecoveryObserver)
            }
        }

        analyticsObserver.trackErrorRecovery(ifErrorOn: experience)
        stateMachine.clientAppcuesDelegate = appcues?.experienceDelegate
        stateMachine.transitionAndObserve(.startExperience(experience), filter: experience.instanceID) { result in
            switch result {
            case .success(.renderingStep):
                DispatchQueue.main.async { completion?(.success(())) }
                return true
            case let .failure(error):
                DispatchQueue.main.async { completion?(.failure(error)) }
                return true
            default:
                // Keep observing until we get to the target state
                return false
            }
        }
    }

    private func show(qualifiedExperiences: [ExperienceData], completion: ((Result<Void, Error>) -> Void)?) {
        guard let experience = qualifiedExperiences.first else {
            // If given an empty list of qualified experiences, complete with a success because this function has completed without error.
            // This function only recurses on a non-empty case, so this block only applies to the initial external call.
            completion?(.success(()))
            return
        }

        show(experience: experience) { result in
            switch result {
            case .success:
                completion?(result)
            case .failure(ExperienceRendererError.noStateMachine):
                // If there's no state machine available, there's no point in trying the remaining experiences for the same context
                completion?(result)
            case .failure:
                let remainingExperiences = qualifiedExperiences.dropFirst()
                if remainingExperiences.isEmpty {
                    completion?(result)
                } else {
                    self.show(qualifiedExperiences: Array(remainingExperiences), completion: completion)
                }
            }
        }
    }

    func show(step stepRef: StepReference, inContext context: RenderContext, completion: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(step: stepRef, inContext: context, completion: completion)
            }
            return
        }

        guard let stateMachine = stateMachines[context] else {
            completion?()
            return
        }

        stateMachine.transitionAndObserve(.startStep(stepRef)) { result in
            switch result {
            case .success(.renderingStep):
                DispatchQueue.main.async { completion?() }
                return true
            case .success(.idling):
                if stepRef == .offset(1) {
                    // If the experience is dismissed and resets to the idling state,
                    // then by definition the progression to the next step has completed.
                    DispatchQueue.main.async { completion?() }
                    return true
                }
                return false
            case .failure:
                // Done observing, something went wrong
                DispatchQueue.main.async { completion?() }
                return true
            default:
                // Keep observing until we get to the target state
                return false
            }
        }
    }

    func dismiss(inContext context: RenderContext, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.dismiss(inContext: context, markComplete: markComplete, completion: completion)
            }
            return
        }

        guard let stateMachine = stateMachines[context] else {
            completion?(.failure(ExperienceRendererError.noStateMachine))
            return
        }

        stateMachine.transitionAndObserve(.endExperience(markComplete: markComplete)) { [weak self] result in
            switch result {
            case .success(.idling):
                self?.pendingPreviewExperiences.removeValue(forKey: context)
                self?.potentiallyRenderableExperiences.removeValue(forKey: context)
                DispatchQueue.main.async { completion?(.success(())) }
                return true

            // These two cases handle dismissing an experience that's in the process of presenting a step group.
            case .success(.renderingStep):
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(inContext: context, markComplete: markComplete, completion: completion)
                }
                return true
            case .failure(.noTransition(currentState: .beginningExperience)),
                    .failure(.noTransition(.beginningStep)):
                // If no valid transition because the experience is starting, we want to wait for a valid point to dismiss
                // (ie the .renderingStep case above) instead of completing with an error like the case below.
                return false

            case .failure(let error):
                // Done observing, something went wrong
                DispatchQueue.main.async { completion?(.failure(error)) }
                return true
            default:
                // Keep observing until we get to the target state
                return false
            }
        }
    }

    func experienceData(forContext context: RenderContext) -> ExperienceData? {
        stateMachines[context]?.state.currentExperienceData
    }

    func stepIndex(forContext context: RenderContext) -> Experience.StepIndex? {
        stateMachines[context]?.state.currentStepIndex
    }

    func owner(forContext context: RenderContext) -> StateMachineOwning? {
        stateMachines[ownerFor: context]
    }

    func resetAll() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.resetAll()
            }
            return
        }

        pendingPreviewExperiences.removeAll()
        potentiallyRenderableExperiences.removeAll()

        stateMachines.forEach { _, stateMachineOwning in
            stateMachineOwning.reset()
        }
    }

    /// Reset only the owned `Self.stateMachine` instance in conformance to `StateMachineOwning`.
    func reset() {
        stateMachine?.removeAnalyticsObserver()
        dismiss(inContext: .modal, markComplete: false, completion: nil)
    }

    private func track(experiment: Experiment?) {
        guard let experiment = experiment,
              let analyticsPublisher = appcues?.container.resolve(AnalyticsPublishing.self) else {
            return
        }

        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: "appcues:experiment_entered", interactive: false),
            properties: [
                "experimentId": experiment.experimentID.appcuesFormatted,
                "experimentGroup": experiment.group,
                "experimentExperienceId": experiment.experienceID.appcuesFormatted,
                "experimentContentType": experiment.contentType,
                "experimentGoalId": experiment.goalID
            ],
            isInternal: true
        ))
    }
}
