//
//  ActionRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal class ActionRegistry {
    private var actions: [String: ExperienceAction.Type] = [:]

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

    func actionClosures(for actionModels: [Experience.Action]) -> [() -> Void] {
        actionModels.compactMap { [appcues] actionModel in
            if let actionInstance = actions[actionModel.type]?.init(config: actionModel.config) {
                return { actionInstance.execute(inContext: appcues) }
            }
            return nil
        }
    }
}
