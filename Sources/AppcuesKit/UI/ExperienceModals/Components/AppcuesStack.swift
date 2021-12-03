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

        switch model.orientation {
        case .vertical:
            VStack(alignment: style.horizontalAlignment, spacing: CGFloat(model.spacing ?? 0)) {
                ForEach(model.items) {
                    AnyView($0.view)
                }
            }
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyAllAppcues(style)
        case .horizontal:
            HStack(alignment: style.verticalAlignment, spacing: CGFloat(model.spacing ?? 0)) {
                ForEach(model.items) {
                    AnyView($0.view)
                }
            }
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyAllAppcues(style)
        }
    }
}

#if DEBUG
internal struct AppcuesStackPreview: PreviewProvider {

    static var previews: some View {
        // swiftlint:disable:next closure_body_length
        Group {
            AppcuesStack(model: EC.StackModel(
                id: UUID(),
                orientation: .vertical,
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
                spacing: 8,
                items: [
                    .text(EC.textTitle),
                    .text(EC.textSubtitle),
                    .button(EC.buttonPrimary)
                ],
                style: EC.Style(
                    spacing: 48,
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
