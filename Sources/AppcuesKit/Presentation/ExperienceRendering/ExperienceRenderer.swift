//
//  ExperienceRenderer.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-20.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal protocol ExperienceRendering {
    func show(experience: Experience, published: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func show(qualifiedExperiences: [Experience], completion: ((Result<Void, Error>) -> Void)?)
    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?)
    func dismissCurrentExperience(markComplete: Bool, completion: (() -> Void)?)
}

@available(iOS 13.0, *)
internal class ExperienceRenderer: ExperienceRendering {

    private let stateMachine: ExperienceStateMachine
    private let analyticsObserver: ExperienceStateMachine.AnalyticsObserver
    private let appcues: Appcues
    private let config: Appcues.Config

    init(container: DIContainer) {
        self.appcues = container.resolve(Appcues.self)
        self.config = container.resolve(Appcues.Config.self)

        // two items below are not registered/resolved directly from container as they
        // are considered private implementation details of the ExperienceRenderer - helpers.
        self.stateMachine = ExperienceStateMachine(container: container)
        self.analyticsObserver = ExperienceStateMachine.AnalyticsObserver(container: container)
    }

    func show(experience: Experience, published: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        DispatchQueue.main.async {
            // only track analytics on published experiences (not previews)
            // and only add the observer if the state machine is idling, otherwise there's already another experience in-flight
            if published && self.stateMachine.state == .idling {
                self.stateMachine.addObserver(self.analyticsObserver)
            }
            self.stateMachine.clientAppcuesDelegate = self.appcues.delegate
            self.stateMachine.transitionAndObserve(.startExperience(experience), filter: experience.instanceID) { result in
                switch result {
                case .success(.renderingStep):
                    completion?(.success(()))
                    return true
                case let .failure(error):
                    completion?(.failure(error))
                    return true
                default:
                    // Keep observing until we get to the target state
                    return false
                }
            }
        }
    }

    func show(qualifiedExperiences: [Experience], completion: ((Result<Void, Error>) -> Void)?) {
        guard let experience = qualifiedExperiences.first else {
            // If given an empty list of qualified experiences, complete with a success because this function has completed without error.
            // This function only recurses on a non-empty case, so this block only applies to the initial external call.
            completion?(.success(()))
            return
        }

        show(experience: experience, published: true) { result in
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
                completion?()
                return true
            case .failure:
                // Done observing, something went wrong
                completion?()
                return true
            default:
                // Keep observing until we get to the target state
                return false
            }
        }
    }

    func dismissCurrentExperience(markComplete: Bool, completion: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.dismissCurrentExperience(markComplete: markComplete, completion: completion)
            }
            return
        }

        stateMachine.transitionAndObserve(.endExperience(markComplete: markComplete)) { result in
            switch result {
            case .success(.idling):
                completion?()
                return true
            case .failure:
                // Done observing, something went wrong
                completion?()
                return true
            default:
                // Keep observing until we get to the target state
                return false
            }
        }
    }
}
