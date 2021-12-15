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

internal class ExperienceRenderer {

    private let stateMachine: ExperienceStateMachine

    private let appcues: Appcues
    private let config: Appcues.Config
    private let styleLoader: StyleLoader
    private let analyticsPublisher: AnalyticsPublisher
    private let storage: Storage

    init(container: DIContainer) {
        self.appcues = container.resolve(Appcues.self)
        self.storage = container.resolve(Storage.self)
        self.config = container.resolve(Appcues.Config.self)
        self.styleLoader = container.resolve(StyleLoader.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublisher.self)

        self.stateMachine = ExperienceStateMachine(container: container)
        stateMachine.experienceLifecycleEventDelegate = self
    }

    func show(experience: Experience) {
        stateMachine.clientAppcuesDelegate = appcues.delegate
        stateMachine.transition(to: .begin(experience))
    }

    func show(stepInCurrentExperience stepRef: StepReference) {
        stateMachine.transition(to: .beginStep(stepRef))
    }

    func dismissCurrentExperience() {
        stateMachine.transition(to: .empty)
    }

    // Show a specified flow model on top of the current application.
    func show(flow: Flow) {
        // TODO: [SC-28964] Tracking the `appcues:flow_attempted` event here is temporary (just so we can see it in the debugger.

        let flowProperties: [String: Any] = [
            "flowId": flow.id,
            "flowName": flow.name,
            "flowType": flow.type.rawValue,
            "flowVersion": round(flow.updatedAt.timeIntervalSince1970 * 1_000),
            // "sessionId": 1635781664936,
            "localeName": "default",
            "localeId": "default"
        ]
        analyticsPublisher.track(name: "appcues:flow_attempted", properties: flowProperties, sync: false)

        guard let modalStepGroup: ModalGroup = flow.steps.compactMap({ $0 as? ModalGroup }).first else {
            // Currently only supporting a single ModalGroup. Additional modal groups or other types aren't supported yet.
            self.config.logger.error("Cannot show flow %{public}s because it has no modal groups", flow.id)
            return
        }

        DispatchQueue.main.async {
            guard let topController = UIApplication.shared.topViewController() else {
                self.config.logger.error("Could not determine top view controller")
                return
            }

            let viewController = ModalGroupViewController(modalStepGroup: modalStepGroup, styleLoader: self.styleLoader)
            topController.present(viewController, animated: true)

            self.storage.lastContentShownAt = Date()
        }
    }
}

extension ExperienceRenderer: ExperienceEventDelegate {
    func lifecycleEvent(_ event: ExperienceLifecycleEvent) {
        // TODO: Studio currently operates off of step-child events, so send those along, but in this temporary manner
        // since eventually appcues:step_child_error, appcues:step_child_activated, and appcues:step_child_deactivated
        // should be unneeded.
        // This assumes the experience JSON step.id is actually the step child ID from studio, and that there's only
        // ever one step per group in the web studio flow.
        switch event {
        case .stepError:
            var properties = event.properties
            properties["stepChildId"] = properties["stepId"]
            properties["stepChildNumber"] = 0
            analyticsPublisher.track(name: "appcues:step_child_error", properties: properties, sync: false)
        case .stepCompleted:
            var properties = event.properties
            properties["stepChildId"] = properties["stepId"]
            properties["stepChildNumber"] = 0
            analyticsPublisher.track(name: "appcues:step_child_deactivated", properties: properties, sync: false)
        default:
            break
        }

        // TODO: Charles causes an infinite event tracking loop here if Map Local is being used to return an experience
        analyticsPublisher.track(name: event.name, properties: event.properties, sync: false)

        switch event {
        case .stepStarted:
            var properties = event.properties
            properties["stepChildId"] = properties["stepId"]
            properties["stepChildNumber"] = 0
            analyticsPublisher.track(name: "appcues:step_child_activated", properties: properties, sync: false)
        default:
            break
        }
    }
}

extension ExperienceRenderer {
    enum StepReference {
        case index(Int)
        case offset(Int)

        func resolve(currentIndex: Int) -> Int {
            switch self {
            case .index(let index):
                return index
            case .offset(let offset):
                return currentIndex + offset
            }
        }
    }
}
