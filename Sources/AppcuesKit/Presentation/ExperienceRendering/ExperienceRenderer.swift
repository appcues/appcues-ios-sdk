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
    func show(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?)
    func show(qualifiedExperiences: [ExperienceData], completion: ((Result<Void, Error>) -> Void)?)
    func show(step stepRef: StepReference, experienceID: InstanceID?, completion: (() -> Void)?)
    func dismiss(experienceID: InstanceID?, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func experienceData(experienceID: InstanceID?) -> ExperienceData?
    func stepIndex(experienceID: InstanceID?) -> Experience.StepIndex?
}

internal enum ExperienceRendererError: Error {
    case experimentControl
}

@available(iOS 13.0, *)
internal class ExperienceRenderer: ExperienceRendering {

    private weak var container: DIContainer?

    // Shared machine, used for modal experiences - only supports one experience running at a time.
    private let sharedStateMachine: ExperienceStateMachine

    // Mapping of ``Experience.instanceID`` -> state machine.
    // Used for non-modal experiences that can have more than one running in parallel.
    private var experienceStateMachines: [InstanceID: ExperienceStateMachine] = [:]

    private let analyticsObserver: ExperienceStateMachine.AnalyticsObserver
    private weak var appcues: Appcues?
    private let config: Appcues.Config

    init(container: DIContainer) {
        self.container = container
        self.appcues = container.owner
        self.config = container.resolve(Appcues.Config.self)

        // two items below are not registered/resolved directly from container as they
        // are considered private implementation details of the ExperienceRenderer - helpers.
        self.sharedStateMachine = ExperienceStateMachine(container: container)
        self.analyticsObserver = ExperienceStateMachine.AnalyticsObserver(container: container)
    }

    func show(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?) {
        guard let container = container else { return }

        let stateMachine: ExperienceStateMachine

        if experience.isNonModal {
            // if the experience is non-modal, get or create the state machine for rendering
            if let experienceStateMachine = experienceStateMachines[experience.instanceID] {
                stateMachine = experienceStateMachine
            } else {
                stateMachine = ExperienceStateMachine(container: container)
                stateMachine.addObserver(
                    StateMachineCleanupObserver(experienceRenderer: self, experienceID: experience.instanceID)
                )
                experienceStateMachines[experience.instanceID] = stateMachine
            }
        } else {
            // if it is modal, use the shared state machine
            stateMachine = sharedStateMachine
        }

        show(experience: experience, in: stateMachine, completion: completion)
    }

    func show(qualifiedExperiences: [ExperienceData], completion: ((Result<Void, Error>) -> Void)?) {
        let (nonModal, modal) = qualifiedExperiences.separate { $0.isNonModal }

        // for the overall success/failure completion - we have potentially multiple experiences being rendered from the
        // response. If any fail, we'll return a failure with the first known failure error. Otherwise, return success.
        var failureResult: Result<Void, Error>?
        showNonModal(qualifiedExperiences: nonModal) { result in
            if case .failure = result, failureResult == nil {
                failureResult = result
            }
        }
        showModal(qualifiedExperiences: modal) { result in
            if case .failure = result, failureResult == nil {
                failureResult = result
            }
        }

        if let failureResult = failureResult {
            completion?(failureResult)
        } else {
            completion?(.success(()))
        }
    }

    func show(step stepRef: StepReference, experienceID: InstanceID?, completion: (() -> Void)?) {
        let stateMachine = stateMachine(experienceID: experienceID)
        show(step: stepRef, in: stateMachine, completion: completion)
    }

    func dismiss(experienceID: InstanceID?, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        let stateMachine = stateMachine(experienceID: experienceID)
        endExperience(in: stateMachine, markComplete: markComplete, completion: completion)
    }

    func experienceData(experienceID: InstanceID?) -> ExperienceData? {
        stateMachine(experienceID: experienceID).state.currentExperienceData
    }

    func stepIndex(experienceID: InstanceID?) -> Experience.StepIndex? {
        stateMachine(experienceID: experienceID).state.currentStepIndex
    }

    func completeExperience(experienceID: InstanceID) {
        experienceStateMachines.removeValue(forKey: experienceID)
    }

    private func stateMachine(experienceID: InstanceID?) -> ExperienceStateMachine {
        if let experienceID = experienceID, let experienceStateMachine = experienceStateMachines[experienceID] {
            // if the given experienceID represents a non-modal experience running its own state machine, use it.
            return experienceStateMachine
        } else {
            // otherwise we'll use the shared state machine
            return sharedStateMachine
        }
    }

    private func show(experience: ExperienceData, in stateMachine: ExperienceStateMachine, completion: ((Result<Void, Error>) -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(experience: experience, in: stateMachine, completion: completion)
            }
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
            endExperience(in: stateMachine, markComplete: false) { result in
                switch result {
                case .success:
                    self.show(experience: experience, in: stateMachine, completion: completion)
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

    private func showModal(qualifiedExperiences: [ExperienceData], completion: ((Result<Void, Error>) -> Void)?) {
        guard let experience = qualifiedExperiences.first else {
            // If given an empty list of qualified modal experiences, return because this function has completed.
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

    private func showNonModal(qualifiedExperiences: [ExperienceData], completion: ((Result<Void, Error>) -> Void)?) {
        // for the overall success/failure completion - we have potentially multiple experiences being rendered from the
        // response.  If any fail, we'll return a failure with the first known failure error.  Otherwise, return success.
        var failureResult: Result<Void, Error>?
        qualifiedExperiences.forEach {
            self.show(experience: $0) { result in
                if case .failure = result, failureResult == nil {
                    failureResult = result
                }
            }
        }

        if let failureResult = failureResult {
            completion?(failureResult)
        } else {
            completion?(.success(()))
        }
    }

    private func show(step stepRef: StepReference, in stateMachine: ExperienceStateMachine, completion: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(step: stepRef, in: stateMachine, completion: completion)
            }
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

    private func endExperience(in stateMachine: ExperienceStateMachine, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.endExperience(in: stateMachine, markComplete: markComplete, completion: completion)
            }
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
                    self?.endExperience(in: stateMachine, markComplete: markComplete, completion: completion)
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
}

@available(iOS 13.0, *)
private extension ExperienceRenderer {

    // helper observer used to clean up the mapping of experience state machines when
    // an experience is completed
    class StateMachineCleanupObserver: ExperienceStateObserver {

        private let experienceID: InstanceID
        private let experienceRenderer: ExperienceRenderer

        init(experienceRenderer: ExperienceRenderer, experienceID: InstanceID) {
            self.experienceRenderer = experienceRenderer
            self.experienceID = experienceID
        }

        func evaluateIfSatisfied(result: StateResult) -> Bool {
            if case .success(.idling) = result {
                experienceRenderer.completeExperience(experienceID: experienceID)
                return true
            }
            return false
        }
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

@available(iOS 13.0, *)
extension Experience {
    var isNonModal: Bool {
        // TODO: detect non-modal experiences
        return false
    }
}
