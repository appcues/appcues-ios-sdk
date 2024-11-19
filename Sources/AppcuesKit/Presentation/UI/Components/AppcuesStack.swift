//
//  AppcuesStack.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesStack: View {
    let model: ExperienceComponent.StackModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        switch (model.orientation, model.distribution) {
        case (.vertical, _):
            VStack(alignment: style.horizontalAlignment, spacing: CGFloat(model.spacing ?? 0)) {
                ForEach(model.items) {
                    AnyView($0.view)
                }
            }
            .setupActions(on: viewModel, for: model)
            .applyAllAppcues(style)
        case (.horizontal, .center),
            (.horizontal, .none):
            HStack(alignment: style.verticalAlignment, spacing: CGFloat(model.spacing ?? 0)) {
                ForEach(model.items) {
                    AnyView($0.view)
                }
            }
            .setupActions(on: viewModel, for: model)
            .applyAllAppcues(style)
        case (.horizontal, .equal):
            EqualWidthStack(alignment: style.verticalAlignment, spacing: CGFloat(model.spacing ?? 0), itemCount: model.items.count) {
                ForEach(model.items) {
                    let itemAlignment = Alignment(
                        vertical: $0.style?.verticalAlignment,
                        horizontal: $0.style?.horizontalAlignment
                    )
                    // `maxWidth: .infinity` allows for horizontal alignment options to work
                    // `maxHeight: .infinity` allows for vertical alignment options to work
                    AnyView($0.view.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: itemAlignment ?? .center))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .setupActions(on: viewModel, for: model)
            .applyAllAppcues(style)
        }
    }
}
