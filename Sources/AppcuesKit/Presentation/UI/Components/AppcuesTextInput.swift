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

    var body: some View {
        let style = AppcuesStyle(from: model.style)
        let textFieldStyle = AppcuesStyle(from: model.textFieldStyle)

        VStack(alignment: style.horizontalAlignment, spacing: 0) {
            ExperienceComponent.text(model.label).view

            let binding = viewModel.formBinding(for: model.id)

            MultilineTextView(text: binding, model: model)
                .frame(height: height)
                .overlay(placeholder(binding), alignment: .topLeading)
                .applyAllAppcues(textFieldStyle)
        }
        .setupActions(on: viewModel, for: model.id)
        .applyAllAppcues(style)
    }

    @ViewBuilder func placeholder(_ binding: Binding<String>) -> some View {
        if let placeholder = model.placeholder, binding.wrappedValue.isEmpty {
            ExperienceComponent.text(placeholder).view
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                .allowsHitTesting(false)
        }
    }
}
