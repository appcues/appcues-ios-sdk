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

    private var actions: [String: ExperienceAction.Type] = [:]

    private var isProcessing = false
    private var actionQueue: [ExperienceAction] = [] {
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
    }

    func register(action: ExperienceAction.Type) {
        guard actions[action.type] == nil else {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil {
                assertionFailure("Action of type \(action.type) is already registered.")
            }
            #endif
            return
        }

        actions[action.type] = action
    }

    private func processFirstAction() {
        guard !isProcessing, let appcues = appcues else { return }

        if let actionInstance = actionQueue.first {
            isProcessing = true
            actionInstance.execute(inContext: appcues) {
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
    func enqueue(actionModels: [Experience.Action], completion: @escaping () -> Void) {
        let actionInstances = actionModels.compactMap {
            actions[$0.type]?.init(configuration: ExperiencePluginConfiguration($0.configDecoder))
        }
        execute(transformQueue(actionInstances), completion: completion)
    }

    /// Enqueue an array of experience actions instance to be executed. This version is used for post-completion actions on an experience.
    func enqueue(actionInstances: [ExperienceAction]) {
        actionQueue.append(contentsOf: transformQueue(actionInstances))
    }

    /// Enqueue an array of experience action data models to be executed. This version is used for interactive actions that are taken
    /// during an experience, such as button taps.
    func enqueue(actionModels: [Experience.Action], interactionType: String, viewDescription: String?) {
        let actionInstances = actionModels.compactMap {
            actions[$0.type]?.init(configuration: ExperiencePluginConfiguration($0.configDecoder))
        }

        // As a heuristic, take the last action that's `MetadataSettingAction`, since that's most likely
        // to be the action that we'd want to see in the event export.
        let primaryAction = actionInstances.reversed().compactMapFirst { $0 as? MetadataSettingAction }
        let interactionAction = AppcuesStepInteractionAction(
            interactionType: interactionType,
            viewDescription: viewDescription ?? "",
            category: primaryAction?.category ?? "",
            destination: primaryAction?.destination ?? "")

        // Directly enqueue the interactionAction separately from the others so that it can't be modified by the queue transformation.
        actionQueue.append(interactionAction)

        enqueue(actionInstances: actionInstances)
    }

    // Queue transforms are applied in the order of the original queue,
    // and actions added to the queue will not have their queue transform executed.
    private func transformQueue(_ actionInstances: [ExperienceAction]) -> [ExperienceAction] {
        return actionInstances.reduce(actionInstances) { currentQueue, action in
            guard let indexInCurrent = currentQueue.firstIndex(where: { $0 === action }),
                  let transformingAction = action as? ExperienceActionQueueTransforming,
                  let appcues = appcues else { return currentQueue }

            return transformingAction.transformQueue(currentQueue, index: indexInCurrent, inContext: appcues)
        }
    }

    private func execute(_ models: [ExperienceAction], completion: (() -> Void)? = nil) {
        var models = models

        guard let appcues = appcues, !models.isEmpty else {
            completion?()
            return
        }

        let next = models.removeFirst()
        next.execute(inContext: appcues) {
            self.execute(models, completion: completion)
        }
    }
}
