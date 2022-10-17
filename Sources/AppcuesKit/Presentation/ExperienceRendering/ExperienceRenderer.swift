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
    func show(experience: Experience,
              priority: RenderPriority,
              published: Bool,
              experiment: Experiment?,
              completion: ((Result<Void, Error>) -> Void)?)
    func show(qualifiedExperiences: [Experience],
              priority: RenderPriority,
              experiments: [String: Experiment],
              completion: ((Result<Void, Error>) -> Void)?)
    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?)
    func dismissCurrentExperience(markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func getCurrentExperienceData() -> ExperienceData?
    func getCurrentStepIndex() -> Experience.StepIndex?
}

internal enum ExperienceRendererError: Error {
    case experimentControl
}

@available(iOS 13.0, *)
internal class ExperienceRenderer: ExperienceRendering {

    private let stateMachine: ExperienceStateMachine
    private let analyticsObserver: ExperienceStateMachine.AnalyticsObserver
    private weak var appcues: Appcues?
    private let config: Appcues.Config
    private let analyticsPublisher: AnalyticsPublishing

    init(container: DIContainer) {
        self.appcues = container.owner
        self.config = container.resolve(Appcues.Config.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublishing.self)

        // two items below are not registered/resolved directly from container as they
        // are considered private implementation details of the ExperienceRenderer - helpers.
        self.stateMachine = ExperienceStateMachine(container: container)
        self.analyticsObserver = ExperienceStateMachine.AnalyticsObserver(container: container)
    }

    func show(experience: Experience,
              priority: RenderPriority,
              published: Bool,
              experiment: Experiment?,
              completion: ((Result<Void, Error>) -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(experience: experience, priority: priority, published: published, experiment: experiment, completion: completion)
            }
            return
        }

        // check if this experience is part of an active experiment
        if let experiment = experiment, let experimentID = experience.experimentID, let group = experiment.group {
            // always send analytics for experiment_entered, with the group
            analyticsPublisher.publish(TrackingUpdate(
                type: .event(name: "appcues:experiment_entered", interactive: false),
                properties: [
                    "experimentId": experimentID,
                    "group": group.rawValue
                ],
                isInternal: true))

            // if this user is in the control group, it should not show
            if group == .control {
                completion?(.failure(ExperienceRendererError.experimentControl))
                return
            }
        }

        if priority == .normal && stateMachine.state != .idling {
            dismissCurrentExperience(markComplete: false) { result in
                switch result {
                case .success:
                    self.show(experience: experience,
                              priority: priority,
                              published: published,
                              experiment: experiment,
                              completion: completion)
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            return
        }

        // only track analytics on published experiences (not previews)
        // and only add the observer if the state machine is idling, otherwise there's already another experience in-flight
        if published && stateMachine.state == .idling {
            self.stateMachine.addObserver(analyticsObserver)
        }
        stateMachine.clientAppcuesDelegate = appcues?.experienceDelegate
        stateMachine.transitionAndObserve(.startExperience(ExperienceData(experience: experience)), filter: experience.instanceID) { result in
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

    func show(qualifiedExperiences: [Experience],
              priority: RenderPriority,
              experiments: [String: Experiment],
              completion: ((Result<Void, Error>) -> Void)?) {
        guard let experience = qualifiedExperiences.first else {
            // If given an empty list of qualified experiences, complete with a success because this function has completed without error.
            // This function only recurses on a non-empty case, so this block only applies to the initial external call.
            completion?(.success(()))
            return
        }

        var experiment: Experiment?
        if let experimentID = experience.experimentID {
            experiment = experiments[experimentID]
        }

        show(experience: experience, priority: priority, published: true, experiment: experiment) { result in
            switch result {
            case .success:
                completion?(result)
            case .failure:
                let remainingExperiences = qualifiedExperiences.dropFirst()
                if remainingExperiences.isEmpty {
                    completion?(result)
                } else {
                    self.show(qualifiedExperiences: Array(remainingExperiences),
                              priority: priority,
                              experiments: experiments,
                              completion: completion)
                }
            }
        }
    }

    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(stepInCurrentExperience: stepRef, completion: completion)
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

    func dismissCurrentExperience(markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        // Force `markComplete` to be true if dismissing from the last step in the experience.
        let currentStepIndex = getCurrentStepIndex()
        let forceMarkComplete = currentStepIndex != nil && currentStepIndex == getCurrentExperienceData()?.stepIndices.last
        let markComplete = markComplete || forceMarkComplete

        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.dismissCurrentExperience(markComplete: markComplete, completion: completion)
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
                    self?.dismissCurrentExperience(markComplete: markComplete, completion: completion)
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

    func getCurrentExperienceData() -> ExperienceData? {
        stateMachine.state.currentExperienceData
    }

    func getCurrentStepIndex() -> Experience.StepIndex? {
        stateMachine.state.currentStepIndex
    }
}
