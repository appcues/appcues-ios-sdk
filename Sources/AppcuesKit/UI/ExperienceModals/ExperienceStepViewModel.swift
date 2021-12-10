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
        case longPress
    }

    let step: Experience.Step
    private var actions: [UUID: [Experience.Action]]
    private let actionRegistry: ActionRegistry

    init(step: Experience.Step, actionRegistry: ActionRegistry) {
        self.step = step
        // Update the action list to be keyed by the UUID.
        self.actions = step.actions.reduce(into: [:]) { dict, item in
            guard let uuidKey = UUID(uuidString: item.key) else { return }
            dict[uuidKey] = item.value
        }
        self.actionRegistry = actionRegistry
    }

    /// Returns the actions for the specific component grouped by `ActionType`.
    func groupedActionHandlers(for id: UUID) -> [ActionType: [() -> Void]] {
        guard let componentActions = actions[id] else { return [:] }

        // (trailing closure in init would be less readable)
        // swiftlint:disable:next trailing_closure
        return Dictionary(grouping: componentActions, by: { $0.trigger })
            .reduce(into: [:]) { dict, item in
                guard let actionType = ActionType(rawValue: item.key) else { return }
                dict[actionType] = actionRegistry.actionClosures(for: item.value)
            }
    }
}
