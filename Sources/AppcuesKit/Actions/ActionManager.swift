//
//  ActionManager.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal class ActionManager {
    var actions: [ExperienceAction.Type] = []

    let container: DIContainer

    init(container: DIContainer) {
        self.container = container

        // Register default actions
        register(action: AppcuesCloseAction.self)
        register(action: AppcuesLinkAction.self)
        register(action: AppcuesLaunchExperienceAction.self)
        register(action: AppcuesTrackAction.self)
        register(action: AppcuesUpdateProfileAction.self)
    }

    func register(action: ExperienceAction.Type) {
        actions.append(action)
    }

    func actionClosures(for actionModels: [Experience.Action]) -> [() -> Void] {
        actionModels.compactMap { actionModel in
            actions.first { $0.type == actionModel.type }?.init(config: actionModel.config)
        }
        .map { [container] actionInstance in
            return { actionInstance.execute(inContext: container.resolve(Appcues.self)) }
        }
    }
}
