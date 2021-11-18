//
//  ExperienceRenderer.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-20.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class ExperienceRenderer {

    private let config: Appcues.Config
    private let styleLoader: StyleLoader
    private let traitRegistry: TraitRegistry
    private let actionRegistry: ActionRegistry
    private let analyticsPublisher: AnalyticsPublisher
    private let storage: Storage

    init(container: DIContainer) {
        self.storage = container.resolve(Storage.self)
        self.config = container.resolve(Appcues.Config.self)
        self.styleLoader = container.resolve(StyleLoader.self)
        self.traitRegistry = container.resolve(TraitRegistry.self)
        self.actionRegistry = container.resolve(ActionRegistry.self)
        self.analyticsPublisher = container.resolve(AnalyticsPublisher.self)
    }

    func show(experience: Experience) {
        if experience.steps.count > 1 {
            config.logger.log("Experience has more than one step. Currently only the first will be presented.")
        }

        guard let step = experience.steps.first else {
            config.logger.error("Experience has no steps")
            return
        }

        DispatchQueue.main.async {
            guard let topController = UIApplication.shared.topViewController() else {
                self.config.logger.error("Could not determine top view controller")
                return
            }

            let viewModel = ExperienceStepViewModel(step: step, actionRegistry: self.actionRegistry)
            let viewController = ExperienceStepHostingController(rootView: step.content.view, viewModel: viewModel)
            let wrappedViewController = self.traitRegistry.apply(step.traits, to: viewController)

            // this flag tells automatic screen tracking to ignore screens that the SDK is presenting
            objc_setAssociatedObject(wrappedViewController, &UIKitScreenTracking.untrackedScreenKey, true, .OBJC_ASSOCIATION_RETAIN)

            topController.present(wrappedViewController, animated: true)

            self.storage.lastContentShownAt = Date()
        }
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
        analyticsPublisher.track(name: "appcues:flow_attempted", properties: flowProperties)

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
