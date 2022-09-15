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

        fileprivate let type: String
        fileprivate let label: String
        fileprivate var underlyingValue: ValueType
        fileprivate let required: Bool

        var isSatisfied: Bool {
            return !required || underlyingValue.isSet
        }

        internal init(type: String, label: String, value: FormItem.ValueType, required: Bool) {
            self.type = type
            self.label = label
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
extension ExperienceData.StepState {
    func formattedAsProfileUpdate() -> [String: Any] {
        var update: [String: Any] = [:]

        formItems.forEach { _, item in
            update["_appcuesForm_\(item.label.asSlug)"] = item.getValue()
        }

        return update
    }

    func formattedAsDebugData() -> [(title: String, value: String)] {
        return formItems.map { _, formItem in
            (formItem.label, formItem.getValue())
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceData.StepState: Encodable {
    enum ItemKeys: CodingKey {
        case fieldId, fieldType, fieldRequired, value, label
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        try formItems.forEach { id, formItem in
            var itemContainer = container.nestedContainer(keyedBy: ItemKeys.self)
            try itemContainer.encode(id, forKey: .fieldId)
            try itemContainer.encode(formItem.type, forKey: .fieldType)
            try itemContainer.encode(formItem.required, forKey: .fieldRequired)
            try itemContainer.encode(formItem.getValue(), forKey: .value)
            try itemContainer.encode(formItem.label, forKey: .label)
        }
    }
}

private extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    var asSlug: String {
        guard let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) else { return self }

        let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
        let result = urlComponents.filter { !$0.isEmpty }.joined(separator: "-")

        return result
    }
}
