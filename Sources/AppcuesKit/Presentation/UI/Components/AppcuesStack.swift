//
//  AppcuesStack.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
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
            .setupActions(on: viewModel, for: model.id)
            .applyAllAppcues(style)
        case (.horizontal, .center),
            (.horizontal, .none):
            HStack(alignment: style.verticalAlignment, spacing: CGFloat(model.spacing ?? 0)) {
                ForEach(model.items) {
                    AnyView($0.view)
                }
            }
            .setupActions(on: viewModel, for: model.id)
            .applyAllAppcues(style)
        case (.horizontal, .equal):
            HStack(alignment: style.verticalAlignment, spacing: CGFloat(model.spacing ?? 0)) {
                ForEach(model.items) {
                    let itemAlignment = Alignment(
                        vertical: $0.style?.verticalAlignment,
                        horizontal: $0.style?.horizontalAlignment
                    )
                    // `maxWidth: .infinity` sets equal widths
                    // `maxHeight: .infinity` combined with `.fixedSize` below set equal heights
                    AnyView($0.view.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: itemAlignment ?? .center))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .setupActions(on: viewModel, for: model.id)
            .applyAllAppcues(style)
        }
    }
}
