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
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyAllAppcues(style)
        case (.horizontal, .center),
            (.horizontal, .none):
            HStack(alignment: style.verticalAlignment, spacing: CGFloat(model.spacing ?? 0)) {
                ForEach(model.items) {
                    AnyView($0.view)
                }
            }
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
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
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyAllAppcues(style)
        }
    }
}

#if DEBUG
@available(iOS 13.0, *)
internal struct AppcuesStackPreview: PreviewProvider {

    static var previews: some View {
        // swiftlint:disable:next closure_body_length
        Group {
            AppcuesStack(model: EC.StackModel(
                id: UUID(),
                orientation: .vertical,
                distribution: .center,
                spacing: 8,
                items: [
                    .text(EC.textTitle),
                    .text(EC.textSubtitle),
                    .button(EC.buttonPrimary)
                ],
                style: EC.Style(backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesStack(model: EC.StackModel(
                id: UUID(),
                orientation: .vertical,
                distribution: .center,
                spacing: 48,
                items: [
                    .text(EC.textTitle),
                    .text(EC.textSubtitle),
                    .button(EC.buttonPrimary)
                ],
                style: EC.Style(
                    horizontalAlignment: "leading",
                    paddingTop: 8,
                    paddingLeading: 8,
                    paddingBottom: 8,
                    paddingTrailing: 8,
                    backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesStack(model: EC.StackModel(
                id: UUID(),
                orientation: .horizontal,
                distribution: .center,
                spacing: 8,
                items: [
                    .image(EC.imageSymbol),
                    .text(EC.textPlain)
                ],
                style: EC.Style(backgroundColor: "#eee"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

        }
    }
}
#endif
