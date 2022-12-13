//
//  AppcuesOptionSelect.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-11.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesOptionSelect: View {
    private struct OptionItem: Identifiable {
        var id: String
        let content: ExperienceComponent
        let isSelected: Binding<Bool>
    }

    let model: ExperienceComponent.OptionSelectModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel
    @EnvironmentObject var stepState: ExperienceData.StepState

    var body: some View {
        let style = AppcuesStyle(from: model.style)
        let errorTintColor = stepState.shouldShowError(for: model.id) ? Color(dynamicColor: model.errorLabel?.style?.foregroundColor) : nil

        VStack(alignment: style.horizontalAlignment, spacing: 0) {
            TintedTextView(model: model.label, tintColor: errorTintColor)

            switch (model.selectMode, model.displayFormat) {
            case (.single, .picker):
                Picker(model.label.text, selection: stepState.formBinding(for: model.id)) {
                    ForEach(model.options) { option in
                        option.content.view
                            .tag(option.value)
                    }
                }
            case (.single, .nps):
                NPSView(model: model)
            case (_, .horizontalList):
                HStack(alignment: model.controlPosition?.verticalAlignment ?? .center, spacing: 0) {
                    items
                }
            case (_, .verticalList),
                // fallbacks
                (_, .none), (.multi, .picker), (.multi, .nps):
                VStack(alignment: model.controlPosition?.horizontalAlignment ?? .center, spacing: 0) {
                    items
                }
            }

            if stepState.shouldShowError(for: model.id), let errorLabel = model.errorLabel {
                AppcuesText(model: errorLabel)
            }
        }
        .setupActions(on: viewModel, for: model)
        .applyAllAppcues(style)
    }

    @ViewBuilder var items: some View {
        let primaryColor = stepState.shouldShowError(for: model.id) ? Color(dynamicColor: model.errorLabel?.style?.foregroundColor) : nil

        // each option and its selection state
        let selections: [Binding<Bool>] = model.options.map { stepState.formBinding(for: model.id, value: $0.value) }

        // determine if leading fill is supported for items prior to selected item
        let allowLeadingFill = (model.leadingFill ?? false) && model.selectMode == .single && model.controlPosition == .hidden

        // first item, if any, selected - to check for leading fill
        let firstSelectedIndex = selections.firstIndex { $0.wrappedValue }

        let optionItems: [OptionItem] = model.options.enumerated().map { index, item in
            let isSelected = selections[index]
            var content = (isSelected.wrappedValue) ? (item.selectedContent ?? item.content) : item.content
            if allowLeadingFill,
                let firstSelectedIndex = firstSelectedIndex,
                index < firstSelectedIndex,
                let selectedContent = item.selectedContent {
                // this overrides an unselected item with selected content styling in the leadingFill case
                content = selectedContent
            }
            return OptionItem(id: item.id, content: content, isSelected: isSelected)
        }

        ForEach(optionItems) { item in
            SelectToggleView(selected: item.isSelected, primaryColor: primaryColor, model: model) { item.content.view }
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceComponent.OptionSelectModel.ControlPosition {
    var verticalAlignment: VerticalAlignment? {
        switch self {
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .leading, .trailing, .hidden:
            return nil
        }
    }

    var horizontalAlignment: HorizontalAlignment? {
        switch self {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .top, .bottom, .hidden:
            return nil
        }
    }
}
