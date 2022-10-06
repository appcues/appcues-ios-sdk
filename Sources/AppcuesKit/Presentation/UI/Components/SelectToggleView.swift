//
//  SelectToggleView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-24.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct SelectToggleView<Content: View>: View {

    enum Appearance {
        case checkbox, radio
    }

    @Binding var selected: Bool
    let primaryColor: Color?
    let model: ExperienceComponent.OptionSelectModel
    @ViewBuilder var content: Content

    @ViewBuilder var control: some View {
        Appearance(model.selectMode).symbol(selected: selected, primaryColor: primaryColor, model: model)
            .imageScale(.large)
            // Ensure the minimum size leaves enough space to be an adequate touch target.
            .frame(minWidth: 48, minHeight: 48)
            // zIndex ensures the image is on top of the content the content can be styled to go under the image.
            .zIndex(1)
    }

    var body: some View {
        Group {
            switch model.controlPosition {
            case .leading:
                HStack(spacing: 0) {
                    control
                    content
                }
            case .trailing:
                HStack(spacing: 0) {
                    content
                    control
                }
            case .top:
                VStack(spacing: 0) {
                    control
                    content
                }
            case .bottom:
                VStack(spacing: 0) {
                    content
                    control
                }
            case .hidden, .none:
                content
            }
        }
        .onTapGesture { self.selected.toggle() }
    }
}

@available(iOS 13.0, *)
extension SelectToggleView.Appearance {
    init(_ mode: ExperienceComponent.OptionSelectModel.SelectMode) {
        switch mode {
        case .single:
            self = .radio
        case .multi:
            self = .checkbox
        }
    }

    @ViewBuilder
    func symbol(selected: Bool, primaryColor: Color?, model: ExperienceComponent.OptionSelectModel) -> some View {
        let primaryColor: Color? = {
            if selected {
                return Color(dynamicColor: model.selectedColor)
            } else if let primaryColor = primaryColor {
                return primaryColor
            } else {
                return Color(dynamicColor: model.unselectedColor)
            }
        }()

        switch (self, selected) {
        case (.checkbox, true):
            if #available(iOS 15.0, *), let checkmarkColor = Color(dynamicColor: model.accentColor), let primaryColor = primaryColor {
                Image(systemName: "checkmark.square.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(checkmarkColor, primaryColor)
            } else {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(primaryColor)
            }
        case (.checkbox, false):
            Image(systemName: "square")
                .foregroundColor(primaryColor)
        case (.radio, true):
            Image(systemName: "circle.inset.filled")
                .foregroundColor(primaryColor)
        case (.radio, false):
            Image(systemName: "circle")
                .foregroundColor(primaryColor)
        }
    }
}
