//
//  ActionRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class ActionRegistry {
    typealias Completion = () -> Void

    private var actions: [String: AppcuesExperienceAction.Type] = [:]

    private var isProcessing = false
    private var actionQueue: [AppcuesExperienceAction] = [] {
        didSet { processFirstAction() }
    }

    private weak var appcues: Appcues?

    init(container: DIContainer) {
        self.appcues = container.owner

        // Register default actions
        register(action: AppcuesCloseAction.self)
        register(action: AppcuesLinkAction.self)
        register(action: AppcuesLaunchExperienceAction.self)
        register(action: AppcuesTrackAction.self)
        register(action: AppcuesUpdateProfileAction.self)
        register(action: AppcuesContinueAction.self)
        register(action: AppcuesSubmitFormAction.self)
        register(action: AppcuesRequestReviewAction.self)
    }

    @discardableResult
    func register(action: AppcuesExperienceAction.Type) -> Bool {
        guard actions[action.type] == nil else {
            appcues?.config.logger.error("Action of type %{public}@ is already registered.", action.type)
            return false
        }

        actions[action.type] = action
        return true
    }

    private func processFirstAction() {
        guard !isProcessing else { return }

        if let actionInstance = actionQueue.first {
            isProcessing = true
            actionInstance.execute {
                DispatchQueue.main.async {
                    // On completion, remove the action, which triggers the didSet to process the remaining action handlers.
                    self.isProcessing = false
                    self.actionQueue.removeFirst()
                }
            }
        }
    }

    /// Enqueue an array of experience action data models to be executed. This version is for non-interactive action execution,
    /// such as actions that execute as part of the navigation to a step.
    func enqueue(
        actionModels: [Experience.Action],
        level: AppcuesExperiencePluginConfiguration.Level,
        renderContext: RenderContext,
        completion: @escaping () -> Void
    ) {
        let actionInstances = actionModels.compactMap {
            actions[$0.type]?.init(configuration: AppcuesExperiencePluginConfiguration(
                $0.configDecoder,
                level: level,
                renderContext: renderContext,
                appcues: appcues
            ))
        }
        execute(transformQueue(actionInstances), completion: completion)
    }

    /// Enqueue the action instances generated from a factory function to be executed.
    /// This version is used for post-completion actions on an experience.
    func enqueue(actionFactory: (Appcues?) -> [AppcuesExperienceAction]) {
        let actionInstances = actionFactory(appcues)
        actionQueue.append(contentsOf: transformQueue(actionInstances))
    }

    /// Enqueue an array of experience action data models to be executed. This version is used for interactive actions that are taken
    /// during an experience, such as button taps.
    func enqueue(
        actionModels: [Experience.Action],
        level: AppcuesExperiencePluginConfiguration.Level,
        renderContext: RenderContext,
        interactionType: String,
        viewDescription: String?
    ) {
        let actionInstances = actionModels.compactMap {
            actions[$0.type]?.init(configuration: AppcuesExperiencePluginConfiguration(
                $0.configDecoder,
                level: level,
                renderContext: renderContext,
                appcues: appcues
            ))
        }

        // As a heuristic, take the last action that's `InteractionLoggingAction`, since that's most likely
        // to be the action that we'd want to see in the event export.
        let primaryAction = actionInstances.reversed().compactMapFirst { $0 as? InteractionLoggingAction }
        let interactionAction = AppcuesStepInteractionAction(
            appcues: appcues,
            renderContext: renderContext,
            interactionType: interactionType,
            viewDescription: viewDescription ?? "",
            category: primaryAction?.category ?? "",
            destination: primaryAction?.destination ?? ""
        )

        // Directly enqueue the interactionAction separately from the others so that it can't be modified by the queue transformation.
        actionQueue.append(interactionAction)

        actionQueue.append(contentsOf: transformQueue(actionInstances))
    }

    // Queue transforms are applied in the order of the original queue,
    // and actions added to the queue will not have their queue transform executed.
    private func transformQueue(_ actionInstances: [AppcuesExperienceAction]) -> [AppcuesExperienceAction] {
        return actionInstances.reduce(actionInstances) { currentQueue, action in
            guard let indexInCurrent = currentQueue.firstIndex(where: { $0 === action }),
                  let transformingAction = action as? ExperienceActionQueueTransforming,
                  let appcues = appcues else { return currentQueue }

            return transformingAction.transformQueue(currentQueue, index: indexInCurrent, inContext: appcues)
        }
    }

    private func execute(_ models: [AppcuesExperienceAction], completion: (() -> Void)? = nil) {
        var models = models

        guard !models.isEmpty else {
            completion?()
            return
        }

        let next = models.removeFirst()
        next.execute {
            self.execute(models, completion: completion)
        }
    }
}
