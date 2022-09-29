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

    /// Enqueue an experience action instance to be executed.
    func enqueue(actionInstances: [ExperienceAction]) {
        actionQueue.append(contentsOf: transformQueue(actionInstances))
    }

    /// Enqueue an experience action data model to be executed.
    func enqueue(actionModels: [Experience.Action]) {
        let actionInstances = actionModels.compactMap {
            actions[$0.type]?.init(config: $0.config)
        }
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
}
