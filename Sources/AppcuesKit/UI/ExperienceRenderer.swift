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
    func show(stepInCurrentExperience stepRef: StepReference)
    func dismissCurrentExperience()
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
        stateMachine.experienceLifecycleEventDelegate = published ? analyticsTracker : nil
        stateMachine.clientAppcuesDelegate = appcues.delegate
        stateMachine.transition(to: .begin(experience))
    }

    func show(stepInCurrentExperience stepRef: StepReference) {
        stateMachine.transition(to: .beginStep(stepRef))
    }

    func dismissCurrentExperience() {
        stateMachine.transition(to: .empty)
    }

}
