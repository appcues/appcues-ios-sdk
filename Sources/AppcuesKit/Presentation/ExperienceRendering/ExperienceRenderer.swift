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
    func show(experience: Experience, priority: RenderPriority, published: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func show(qualifiedExperiences: [Experience], priority: RenderPriority, completion: ((Result<Void, Error>) -> Void)?)
    func show(step stepRef: StepReference, experienceID: String?, completion: (() -> Void)?)
    func dismissExperience(experienceID: String?, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?)
}

@available(iOS 13.0, *)
internal class ExperienceRenderer: ExperienceRendering {

    private weak var container: DIContainer?

    // this is the shared machine, used for modal experiences - only supports one experience
    // running at a time
    private let sharedStateMachine: ExperienceStateMachine

    // this the mapping of experienceID -> state machine, used for non-modal experiences
    // that can have more than one running in parallel
    private var experienceStateMachines: [String: ExperienceStateMachine] = [:]

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

    func show(experience: Experience, priority: RenderPriority, published: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        guard let container = container else { return }

        let stateMachine: ExperienceStateMachine

        if experience.isNonModal {
            // if the experience is non-modal, get or create the state machine for rendering
            if let experienceStateMachine = experienceStateMachines[experience.instanceID.uuidString] {
                stateMachine = experienceStateMachine
            } else {
                stateMachine = ExperienceStateMachine(container: container)
                stateMachine.addObserver(
                    StateMachineCleanupObserver(experienceRenderer: self, experienceID: experience.instanceID.uuidString))
                experienceStateMachines[experience.instanceID.uuidString] = stateMachine
            }
        } else {
            // if it is modal, use the shared state machine
            stateMachine = sharedStateMachine
        }

        show(experience: experience, in: stateMachine, priority: priority, published: published, completion: completion)
    }

    func show(qualifiedExperiences: [Experience], priority: RenderPriority, completion: ((Result<Void, Error>) -> Void)?) {
        let (nonModal, modal) = qualifiedExperiences.separate { $0.isNonModal }

        // for the overall success/failure completion - we have potentially multiple experiences being rendered from the
        // response.  If any fail, we'll return a failure with the first known failure error.  Otherwise, return success.
        var failureResult: Result<Void, Error>?
        showNonModal(qualifiedExperiences: nonModal) { result in
            if case .failure = result, failureResult == nil {
                failureResult = result
            }
        }
        showModal(qualifiedExperiences: modal, priority: priority) { result in
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

    func show(step stepRef: StepReference, experienceID: String?, completion: (() -> Void)?) {

        // by default, we'll show the step in the experience in the shared state machine
        var stateMachine = sharedStateMachine

        // if the given experienceID represents a non-modal experience running its own state machine,
        // use that machine instead.
        if let experienceID = experienceID, let experienceStateMachine = experienceStateMachines[experienceID] {
            stateMachine = experienceStateMachine
        }

        show(step: stepRef, in: stateMachine, completion: completion)
    }

    func dismissExperience(experienceID: String?, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?) {

        // by default, we'll dismiss whats in the shared state machine
        var stateMachine = sharedStateMachine

        // if the given experienceID represents a non-modal experience running its own state machine, dismiss in that
        // machine instead.
        if let experienceID = experienceID, let experienceStateMachine = experienceStateMachines[experienceID] {
            stateMachine = experienceStateMachine
        }

        endExperience(in: stateMachine, markComplete: markComplete, completion: completion)
    }

    func completeExperience(experienceID: String) {
        experienceStateMachines.removeValue(forKey: experienceID)
    }

    private func show(experience: Experience,
                      in stateMachine: ExperienceStateMachine,
                      priority: RenderPriority,
                      published: Bool,
                      completion: ((Result<Void, Error>) -> Void)?) {

        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(experience: experience, in: stateMachine, priority: priority, published: published, completion: completion)
            }
            return
        }

        if priority == .normal && stateMachine.state != .idling {
            endExperience(in: stateMachine, markComplete: false) { result in
                switch result {
                case .success:
                    self.show(experience: experience, in: stateMachine, priority: priority, published: published, completion: completion)
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
            return
        }

        // only track analytics on published experiences (not previews)
        // and only add the observer if the state machine is idling, otherwise there's already another experience in-flight
        if published && stateMachine.state == .idling {
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

    private func showModal(qualifiedExperiences: [Experience], priority: RenderPriority, completion: ((Result<Void, Error>) -> Void)?) {
        guard let experience = qualifiedExperiences.first else {
            // If given an empty list of qualified modal experiences, return because this function has completed.
            // This function only recurses on a non-empty case, so this block only applies to the initial external call.
            completion?(.success(()))
            return
        }

        show(experience: experience, priority: priority, published: true) { result in
            switch result {
            case .success:
                completion?(result)
            case .failure:
                let remainingExperiences = qualifiedExperiences.dropFirst()
                if remainingExperiences.isEmpty {
                    completion?(result)
                } else {
                    self.showModal(qualifiedExperiences: Array(remainingExperiences), priority: priority, completion: completion)
                }
            }
        }
    }

    private func showNonModal(qualifiedExperiences: [Experience], completion: ((Result<Void, Error>) -> Void)?) {
        // for the overall success/failure completion - we have potentially multiple experiences being rendered from the
        // response.  If any fail, we'll return a failure with the first known failure error.  Otherwise, return success.
        var failureResult: Result<Void, Error>?
        qualifiedExperiences.forEach {
            self.show(experience: $0, priority: .low, published: true) { result in
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

        private let experienceID: String
        private let experienceRenderer: ExperienceRenderer

        init(experienceRenderer: ExperienceRenderer, experienceID: String) {
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
}

@available(iOS 13.0, *)
extension Experience {
    var isNonModal: Bool {
        traits.contains { $0.type == AppcuesEmbedTrait.type }
    }
}
