//
//  ExperienceRenderer.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-20.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol ExperienceRendering {
    func show(experience: Experience, published: Bool, completion: ((Result<Void, Error>) -> Void)?)
    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?)
    func dismissCurrentExperience(completion: (() -> Void)?)
}

internal class ExperienceRenderer: ExperienceRendering {

    private let stateMachine: ExperienceStateMachine
    private let analyticsObserver: ExperienceStateMachine.AnalyticsObserver
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
        self.analyticsObserver = ExperienceStateMachine.AnalyticsObserver(container: container)
    }

    func show(experience: Experience, published: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        // only track analytics on published experiences (not previews)
        // and only add the observer if the state machine is idling, otherwise there's already another experience in-flight
        if published && stateMachine.state == .idling {
            stateMachine.addObserver(analyticsObserver)
        }
        stateMachine.clientAppcuesDelegate = appcues.delegate
        DispatchQueue.main.async {
            self.stateMachine.transitionAndObserve(.startExperience(experience)) { result in
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

    func dismissCurrentExperience(completion: (() -> Void)?) {
        stateMachine.transitionAndObserve(.endExperience) { result in
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
