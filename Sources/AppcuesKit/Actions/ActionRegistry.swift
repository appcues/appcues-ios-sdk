//
//  ActionRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal class ActionRegistry {
    private var actions: [ExperienceAction.Type] = []

    private let appcues: Appcues

    init(container: DIContainer) {
        self.appcues = container.resolve(Appcues.self)

        // Register default actions
        register(action: AppcuesCloseAction.self)
        register(action: AppcuesLinkAction.self)
        register(action: AppcuesLaunchExperienceAction.self)
        register(action: AppcuesTrackAction.self)
        register(action: AppcuesUpdateProfileAction.self)
        register(action: AppcuesContinueAction.self)
    }

    func register(action: ExperienceAction.Type) {
        actions.append(action)
    }

    func actionClosures(for actionModels: [Experience.Action]) -> [() -> Void] {
        actionModels.compactMap { [appcues] actionModel in
            // Using a traditional for-loop so we can return as soon as we init our matching item.
            // If there are multiple actions with the same `type`, take the one registered earliest that can be successfully initialized.
            for action in actions where action.type == actionModel.type {
                if let actionInstance = action.init(config: actionModel.config) {
                    return { actionInstance.execute(inContext: appcues) }
                }
            }
            return nil
        }
    }
}
