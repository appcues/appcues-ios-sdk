//
//  ExperienceStepViewModel.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-05.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal class ExperienceStepViewModel: ObservableObject {

    enum ActionType: String {
        case tap
        case longPress
    }

    let step: Experience.Step.Child
    private let actions: [UUID: [Experience.Action]]
    private let actionRegistry: ActionRegistry?
    private let experienceID: String?

    init(step: Experience.Step.Child, actionRegistry: ActionRegistry, experienceID: String) {
        self.step = step
        // Update the action list to be keyed by the UUID.
        self.actions = step.actions.reduce(into: [:]) { dict, item in
            guard let uuidKey = UUID(uuidString: item.key) else { return }
            dict[uuidKey] = item.value
        }
        self.actionRegistry = actionRegistry
        self.experienceID = experienceID
    }

    // Create an empty view model for contexts that require an `ExperienceStepViewModel` but aren't in a step context.
    init() {
        self.step = Experience.Step.Child(
            id: UUID(),
            type: "",
            content: .spacer(ExperienceComponent.SpacerModel(
                id: UUID(),
                spacing: nil,
                style: nil)),
            traits: [],
            actions: [:])
        self.actions = [:]
        self.actionRegistry = nil
        self.experienceID = nil
    }

    func enqueueActions(_ actions: [Experience.Action]) {
        actionRegistry?.enqueue(actionModels: actions, experienceID: experienceID)
    }

    func actions(for id: UUID) -> [ActionType?: [Experience.Action]] {
        // An unknown trigger value will get lumped into Dictionary[nil] and be ignored.
        Dictionary(grouping: actions[id] ?? []) { ActionType(rawValue: $0.trigger) }
    }
}
