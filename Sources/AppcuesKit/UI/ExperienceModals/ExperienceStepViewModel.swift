//
//  ExperienceStepViewModel.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-05.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal class ExperienceStepViewModel: ObservableObject {

    enum ActionType: String {
        case tap
        case doubleTap
        case longPress
    }

    private var actions: [UUID: [Experience.Action]]
    private let actionManager: ActionManager

    init(step: Experience.Step, actionManager: ActionManager) {
        // Update the action list to be keyed by the UUID.
        self.actions = step.actions.reduce(into: [:]) { dict, item in
            guard let uuidKey = UUID(uuidString: item.key) else { return }
            dict[uuidKey] = item.value
        }
        self.actionManager = actionManager
    }

    /// Returns the actions for the specific component grouped by `ActionType`.
    func groupedActionHandlers(for id: UUID) -> [ActionType: [() -> Void]] {
        guard let componentActions = actions[id] else { return [:] }

        return componentActions
            .grouped(by: \.trigger)
            .reduce(into: [:]) { dict, item in
                guard let actionType = ActionType(rawValue: item.key) else { return }
                dict[actionType] = actionManager.actionClosures(for: item.value)
            }
    }
}
