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
    func processAndShow(qualifiedExperiences: [ExperienceData])
    func show(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?)
    func show(step stepRef: StepReference, inContext context: RenderContext, completion: (() -> Void)?)
    func dismiss(inContext context: RenderContext, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func experienceData(forContext context: RenderContext) -> ExperienceData?
    func stepIndex(forContext context: RenderContext) -> Experience.StepIndex?
    func owner(forContext context: RenderContext) -> StateMachineOwning?
}

internal enum RenderContext: Hashable {
    case embed(frameID: String)
    case modal
}

internal enum ExperienceRendererError: Error {
    case noStateMachine
    case experimentControl
}

@available(iOS 13.0, *)
internal class ExperienceRenderer: ExperienceRendering, StateMachineOwning {

    /// State machine for `RenderContext.modal`
    var stateMachine: ExperienceStateMachine?

    private var stateMachines = StateMachineDirectory()
    private var potentiallyRenderableExperiences: [RenderContext: [ExperienceData]] = [:]
    private let analyticsObserver: ExperienceStateMachine.AnalyticsObserver
    private weak var appcues: Appcues?
    private let config: Appcues.Config

    init(container: DIContainer) {
        self.appcues = container.owner
        self.config = container.resolve(Appcues.Config.self)

        // two items below are not registered/resolved directly from container as they
        // are considered private implementation details of the ExperienceRenderer - helpers.
        self.stateMachine = ExperienceStateMachine(container: container)
        self.analyticsObserver = ExperienceStateMachine.AnalyticsObserver(container: container)

        stateMachines[ownerFor: .modal] = self
    }

    func start(owner: StateMachineOwning, forContext context: RenderContext) {
        guard let container = appcues?.container else { return }

        owner.stateMachine = ExperienceStateMachine(container: container)
        stateMachines[ownerFor: context] = owner
        if let pendingExperiences = potentiallyRenderableExperiences[context] {
            show(qualifiedExperiences: pendingExperiences, completion: nil)
        }
    }

    // TODO: this only gets called when the array isnt empty (AnalyticsTracker does this), so we aren't clearing the cache unless there's at least one new thing.
    func processAndShow(qualifiedExperiences: [ExperienceData]) {
        let shouldClearCache = qualifiedExperiences.contains(where: { $0.trigger == .qualification(reason: .screenView) })
        if shouldClearCache {
            // TODO: error events for embeds that didn't show because there was no Frame
            potentiallyRenderableExperiences = [:]
            stateMachines.cleanup()
        }

        // Add new experiences, replacing any existing ones
        let grouped = Dictionary(grouping: qualifiedExperiences) { $0.renderContext }
        potentiallyRenderableExperiences = potentiallyRenderableExperiences.merging(grouped)

        potentiallyRenderableExperiences.forEach { renderContext, qualifiedExperiences in
            show(qualifiedExperiences: qualifiedExperiences) { result in
                print(result)
                if case .success = result {
                    self.potentiallyRenderableExperiences.removeValue(forKey: renderContext)
                }
            }
        }

        // No caching required for modals since they can't be lazy-loaded.
        potentiallyRenderableExperiences.removeValue(forKey: .modal)
    }

    func show(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(experience: experience, completion: completion)
            }
            return
        }

        guard let stateMachine = stateMachines[experience.renderContext] else {
            potentiallyRenderableExperiences[experience.renderContext] = [experience]
            completion?(.failure(ExperienceRendererError.noStateMachine))
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

        // if we get here, either we did not have an experiment, or it is active and did not exit early (not control group).
        // if an active experiment does exist, it should now track the experiment_entered analytic
        track(experiment: experience.experiment)

        // only track analytics on published experiences (not previews)
        // and only add the observer if the state machine is idling, otherwise there's already another experience in-flight
        if experience.published && stateMachine.state == .idling {
            stateMachine.addObserver(analyticsObserver)
        }
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

        stateMachine.transitionAndObserve(.endExperience(markComplete: markComplete)) { result in
            switch result {
            case .success(.idling):
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
