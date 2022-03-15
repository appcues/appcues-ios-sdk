//
//  ExperienceRenderer.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-20.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol ExperienceEventDelegate: AnyObject {
    func lifecycleEvent(_ event: ExperienceLifecycleEvent)
}

internal protocol ExperienceRendering {
    func show(experience: Experience, published: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?)
    func dismissCurrentExperience(completion: (() -> Void)?)
}

internal class ExperienceRenderer: ExperienceRendering {

    private let stateMachine: ExperienceStateMachine
    private let analyticsTracker: ExperienceAnalyticsTracker
    private let appcues: Appcues
    private let config: Appcues.Config
    private let storage: DataStoring

    init(container: DIContainer) {
        self.appcues = container.resolve(Appcues.self)
        self.storage = container.resolve(DataStoring.self)
        self.config = container.resolve(Appcues.Config.self)

        // two items below are not registered/resolved directly from container as they
        // are considered private implementation details of the ExperienceRenderer - helpers.
        self.stateMachine = ExperienceStateMachine(container: container)
        self.analyticsTracker = ExperienceAnalyticsTracker(container: container)
    }

    func show(experience: Experience, published: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        // only listen to experience lifecycle events and track analytics on published experiences (not previews)
        stateMachine.experienceLifecycleEventDelegate = published ? analyticsTracker : nil
        stateMachine.clientAppcuesDelegate = appcues.delegate
        DispatchQueue.main.async {
            self.stateMachine.transitionAndObserve(.startExperience(experience)) { result, _ in
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

    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?) {
        stateMachine.transitionAndObserve(.startStep(stepRef)) { result, _ in
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

    func dismissCurrentExperience(completion: (() -> Void)?) {
        stateMachine.transitionAndObserve(.endExperience) { result, _ in
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
