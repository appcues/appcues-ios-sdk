//
//  AppcuesTextInput.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-15.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesTextInput: View {
    let model: ExperienceComponent.TextInputModel

    var height: Double {
        let lineHeight = (model.textFieldStyle?.fontSize ?? UIFont.labelFontSize) * 1.2
        let padding = 16.0 * 2
        return Double(model.numberOfLines ?? 1) * lineHeight + padding
    }

    @EnvironmentObject var viewModel: ExperienceStepViewModel
    @EnvironmentObject var stepState: ExperienceData.StepState

    var body: some View {
        let style = AppcuesStyle(from: model.style, theme: viewModel.theme)
        let textFieldStyle = AppcuesStyle(from: model.textFieldStyle, theme: viewModel.theme)
        let errorTintColor = stepState.shouldShowError(for: model.id) ? Color(dynamicColor: model.errorLabel?.style?.foregroundColor) : nil

        VStack(alignment: style.horizontalAlignment, spacing: 0) {
            HStack {
                // nil-coalesce to .leading so a non-specified value defaults to leading-aligned
                if HorizontalAlignment(string: model.label.style?.horizontalAlignment) ?? .leading != .leading {
                    Spacer(minLength: 0)
                }
                TintedTextView(model: model.label, tintColor: errorTintColor)
                if HorizontalAlignment(string: model.label.style?.horizontalAlignment) != .trailing {
                    Spacer(minLength: 0)
                }
            }

            let binding = stepState.formBinding(for: model.id)

            MultilineTextView(text: binding, model: model)
                .frame(height: height)
                .overlay(placeholder(binding), alignment: .topLeading)
                .applyAllAppcues(textFieldStyle)
                .overlay(errorBorder(errorTintColor, textFieldStyle))

            if stepState.shouldShowError(for: model.id), let errorLabel = model.errorLabel {
                HStack {
                    if HorizontalAlignment(string: errorLabel.style?.horizontalAlignment) ?? .leading != .leading {
                        Spacer(minLength: 0)
                    }
                    AppcuesText(model: errorLabel)
                    if HorizontalAlignment(string: errorLabel.style?.horizontalAlignment) != .trailing {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .setupActions(on: viewModel, for: model)
        .applyAllAppcues(style)
    }

    @ViewBuilder func placeholder(_ binding: Binding<String>) -> some View {
        if let placeholder = model.placeholder, binding.wrappedValue.isEmpty {
            AppcuesText(model: placeholder)
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                .allowsHitTesting(false)
        }
    }

    // Can't use an `.ifLet()` on the MultilineTextView since it changes the view identity and causes focus issues.
    @ViewBuilder func errorBorder(_ color: Color?, _ style: AppcuesStyle) -> some View {
        if let color = color {
            RoundedRectangle(cornerRadius: style.cornerRadius ?? 0)
                .stroke(color, lineWidth: max(style.borderWidth ?? 0, 1))
        }
    }

}
