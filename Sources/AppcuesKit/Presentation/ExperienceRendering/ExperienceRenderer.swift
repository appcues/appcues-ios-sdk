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
    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?)
    func dismissCurrentExperience(markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?)
}

@available(iOS 13.0, *)
internal class ExperienceRenderer: ExperienceRendering {

    private let stateMachine: ExperienceStateMachine
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
    }

    func show(experience: Experience, priority: RenderPriority, published: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(experience: experience, priority: priority, published: published, completion: completion)
            }
            return
        }

        if priority == .normal && stateMachine.state != .idling {
            dismissCurrentExperience(markComplete: false) { result in
                switch result {
                case .success:
                    self.show(experience: experience, priority: priority, published: published, completion: completion)
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

    func show(qualifiedExperiences: [Experience], priority: RenderPriority, completion: ((Result<Void, Error>) -> Void)?) {
        guard let experience = qualifiedExperiences.first else {
            // If given an empty list of qualified experiences, complete with a success because this function has completed without error.
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
                    self.show(qualifiedExperiences: Array(remainingExperiences), priority: priority, completion: completion)
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
}
