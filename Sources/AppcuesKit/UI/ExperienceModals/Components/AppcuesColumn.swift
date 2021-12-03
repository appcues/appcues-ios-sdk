//
//  AppcuesColumn.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesColumn: View {
    let model: ExperienceComponent.ColumnModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        VStack(alignment: style.horizontalAlignment, spacing: style.spacing) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAllAppcues(style)
    }
}

#if DEBUG
internal struct AppcuesColumnPreview: PreviewProvider {

    static var previews: some View {
        // swiftlint:disable:next closure_body_length
        Group {
            AppcuesColumn(model: EC.ColumnModel(
                id: UUID(),
                items: [
                    .text(EC.textTitle),
                    .text(EC.textSubtitle),
                    .button(EC.buttonPrimary)
                ],
                style: EC.Style(backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesColumn(model: EC.ColumnModel(
                id: UUID(),
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
        }
    }
}
#endif
