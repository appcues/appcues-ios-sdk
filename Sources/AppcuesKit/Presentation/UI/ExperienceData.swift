//
//  ExperienceData.swift
//  AppcuesKit
//
//  Created by Matt on 2022-09-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
@dynamicMemberLookup
internal class ExperienceData {
    let model: Experience
    private let formState: FormState

    internal init(experience: Experience) {
        self.model = experience
        self.formState = FormState(experience: experience)
    }

    func state(for stepID: UUID) -> StepState {
        guard let stepState = formState.steps[stepID] else {
            // This will never happen as long as we ask for a valid `stepID`, but to avoid a crash
            // where there's no environmentObject set, return an empty state.
            // If this does get into the UI, the result will be form controls that don't update.
            return StepState(formItems: [:])
        }

        return stepState
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Experience, T>) -> T {
        return model[keyPath: keyPath]
    }
}

@available(iOS 13.0, *)
extension ExperienceData {
    class FormState {
        var steps: [UUID: StepState] = [:]

        init(experience: Experience) {
            experience.steps.forEach { step in
                step.items.forEach { item in
                    steps[item.id] = StepState(formItems: item.content.formComponents)
                }
            }
        }
    }

    class StepState: ObservableObject {
        @Published var formItems: [UUID: FormItem]

        var stepFormIsComplete: Bool {
            !formItems.contains { !$0.value.isSatisfied }
        }

        init(formItems: [UUID: FormItem]) {
            self.formItems = formItems
        }

        func formBinding(for key: UUID) -> Binding<String> {
            return .init(
                get: { self.formItems[key]?.getValue() ?? "" },
                set: {
                    self.formItems[key]?.setValue($0)
                })
        }

        func formBinding(for key: UUID, value: String) -> Binding<Bool> {
            return .init(
                get: { self.formItems[key]?.contains(searchValue: value) ?? false },
                set: { _ in
                    self.formItems[key]?.setValue(value)
                })
        }
    }

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
