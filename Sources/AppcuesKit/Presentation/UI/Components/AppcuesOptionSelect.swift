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
            case (_, .horizontalList):
                HStack(alignment: model.controlPosition?.verticalAlignment ?? .center, spacing: 0) {
                    items
                }
            case (_, .verticalList),
                // fallbacks
                (_, .none), (.multi, .picker):
                VStack(alignment: model.controlPosition?.horizontalAlignment ?? .center, spacing: 0) {
                    items
                }
            }

            if stepState.shouldShowError(for: model.id), let errorLabel = model.errorLabel {
                AppcuesText(model: errorLabel)
            }
        }
        .setupActions(on: viewModel, for: model.id)
        .applyAllAppcues(style)
    }

    @ViewBuilder var items: some View {
        let primaryColor = stepState.shouldShowError(for: model.id) ? Color(dynamicColor: model.errorLabel?.style?.foregroundColor) : nil

        ForEach(model.options) { option in
            let binding = stepState.formBinding(for: model.id, value: option.value)
            SelectToggleView(
                selected: binding,
                primaryColor: primaryColor,
                model: model
            ) {
                if binding.wrappedValue {
                    (option.selectedContent ?? option.content).view
                } else {
                    option.content.view
                }
            }
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
