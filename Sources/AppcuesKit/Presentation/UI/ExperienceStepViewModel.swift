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

    @Published private var formComponents: [UUID: FormItem]

    var formIsComplete: Bool {
        !formComponents.contains { !$0.value.isSatisfied }
    }

    init(step: Experience.Step.Child, actionRegistry: ActionRegistry) {
        self.step = step
        // Update the action list to be keyed by the UUID.
        self.actions = step.actions.reduce(into: [:]) { dict, item in
            guard let uuidKey = UUID(uuidString: item.key) else { return }
            dict[uuidKey] = item.value
        }
        self.actionRegistry = actionRegistry

        self.formComponents = step.content.formComponents
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
        self.formComponents = [:]
    }

    func enqueueActions(_ actions: [Experience.Action]) {
        actionRegistry?.enqueue(actionModels: actions)
    }

    func actions(for id: UUID) -> [ActionType?: [Experience.Action]] {
        // An unknown trigger value will get lumped into Dictionary[nil] and be ignored.
        Dictionary(grouping: actions[id] ?? []) { ActionType(rawValue: $0.trigger) }
    }

    // MARK: Bindings for SwiftUI form controls

    func formBinding(for key: UUID) -> Binding<String> {
        return .init(
            get: { self.formComponents[key]?.getValue() ?? "" },
            set: { self.formComponents[key]?.setValue($0) })
    }

    func formBinding(for key: UUID, value: String) -> Binding<Bool> {
        return .init(
            get: { self.formComponents[key]?.contains(searchValue: value) ?? false },
            set: { _ in self.formComponents[key]?.setValue(value) })
    }
}

@available(iOS 13.0, *)
extension ExperienceStepViewModel {

    struct FormItem {
        enum ValueType {
            case single(String)
            case multi(Set<String>)

            var isSet: Bool {
                switch self {
                case .single(let value):
                    return !value.isEmpty
                case .multi(let values):
                    return !values.isEmpty
                }
            }

            var value: String {
                switch self {
                case .single(let value):
                    return value
                case .multi(let values):
                    return values.joined(separator: ",")
                }
            }
        }

        private var underlyingValue: ValueType
        private let required: Bool

        var isSatisfied: Bool {
            return !required || underlyingValue.isSet
        }

        internal init(value: FormItem.ValueType, required: Bool) {
            self.underlyingValue = value
            self.required = required
        }

        func getValue() -> String {
            underlyingValue.value
        }

        mutating func setValue(_ newValue: String) {
            switch underlyingValue {
            case .single:
                underlyingValue = .single(newValue)
            case .multi(let existingValues):
                // Toggle the value to be included in the set.
                underlyingValue = .multi(existingValues.symmetricDifference([newValue]))
            }
        }

        func contains(searchValue: String) -> Bool {
            switch underlyingValue {
            case .single(let value):
                return value == searchValue
            case .multi(let existingValues):
                return existingValues.contains(searchValue)
            }
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceComponent {
    /// Recursively get all the form components in the `ExperienceContent`.
    var formComponents: [UUID: ExperienceStepViewModel.FormItem] {
        var components: [UUID: ExperienceStepViewModel.FormItem] = [:]

        switch self {
        case .text, .button, .image, .spacer, .embed:
            break
        case .stack(let model):
            model.items.forEach {
                components.merge($0.formComponents, uniquingKeysWith: { first, _ in first })
            }
        case .box(let model):
            model.items.forEach {
                components.merge($0.formComponents, uniquingKeysWith: { first, _ in first })
            }
        case .textInput(let model):
            components[model.id] = .init(
                value: .single(model.defaultValue ?? ""),
                required: model.required ?? false)
        }

        return components
    }
}
