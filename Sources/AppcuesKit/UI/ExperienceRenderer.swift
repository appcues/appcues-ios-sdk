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
    func show(experience: Experience, published: Bool)
    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?)
    func dismissCurrentExperience(completion: (() -> Void)?)
    func add(eventDelegate: ExperienceEventDelegate)
}

internal enum StepReference: Equatable {
    case index(Int)
    case offset(Int)
    case stepID(UUID)

    static func == (lhs: StepReference, rhs: StepReference) -> Bool {
        switch (lhs, rhs) {
        case let (.index(index1), .index(index2)):
            return index1 == index2
        case let (.offset(offset1), .offset(offset2)):
            return offset1 == offset2
        case let (.stepID(id1), .stepID(id2)):
            return id1 == id2
        default:
            return false
        }
    }

    func resolve(experience: Experience, currentIndex: Int) -> Int {
        switch self {
        case .index(let index):
            return index
        case .offset(let offset):
            return currentIndex + offset
        case .stepID(let stepID):
            return experience.steps.firstIndex { $0.id == stepID } ?? -1
        }
    }
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

    func show(experience: Experience, published: Bool) {
        // only listen to experience lifecycle events and track analytics on published experiences (not previews)
        if published {
            stateMachine.experienceLifecycleEventDelegate.add(analyticsTracker)
        } else {
            stateMachine.experienceLifecycleEventDelegate.remove(analyticsTracker)
        }

        stateMachine.clientAppcuesDelegate = appcues.delegate
        DispatchQueue.main.async {
            self.stateMachine.transition(to: .begin(experience))
        }
    }

    func show(stepInCurrentExperience stepRef: StepReference, completion: (() -> Void)?) {
        if let completion = completion {
            stateMachine.experienceLifecycleEventDelegate.add(OneTimeEventDelegate(on: .displayedStep, completion: completion))
        }

        stateMachine.transition(to: .beginStep(stepRef))
    }

    func dismissCurrentExperience(completion: (() -> Void)?) {
        if let completion = completion {
            stateMachine.experienceLifecycleEventDelegate.add(OneTimeEventDelegate(on: .completedStep, completion: completion))
        }

        stateMachine.transition(to: .empty)
    }

    func add(eventDelegate: ExperienceEventDelegate) {
        stateMachine.experienceLifecycleEventDelegate.add(eventDelegate)
    }
}

extension ExperienceRenderer {
    class OneTimeEventDelegate: ExperienceEventDelegate {
        enum SimplifiedLifecycleEvent {
            case displayedStep
            case completedStep
            case error
        }

        private let triggerEvent: SimplifiedLifecycleEvent
        private var completion: (() -> Void)?
        private var strongReference: OneTimeEventDelegate?

        init(on triggerEvent: SimplifiedLifecycleEvent, completion: @escaping () -> Void) {

            self.triggerEvent = triggerEvent
            self.completion = completion
            self.strongReference = self
        }

        func lifecycleEvent(_ event: ExperienceLifecycleEvent) {
            guard completion != nil else { return }
            switch event {
            case .flowAttempted, .stepAttempted:
                return
            case .stepStarted, .flowStarted:
                guard triggerEvent == .displayedStep else { return }
            case .stepInteracted, .stepCompleted, .stepSkipped, .flowCompleted, .flowSkipped:
                guard triggerEvent == .completedStep else { return }
            case .stepError, .stepAborted, .flowError, .flowAborted:
                // continue on to call completion even if it failed so we don't get stuck
                break
            }

            completion?()
            // clear the completion handler after it's called in case this instance isn't garbage collected quickly enough
            completion = nil
            // remove the circular ref so this instance will deinit
            strongReference = nil
        }
    }

}
