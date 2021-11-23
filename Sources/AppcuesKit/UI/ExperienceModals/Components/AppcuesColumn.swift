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
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        VStack(alignment: layout.horizontalAlignment, spacing: layout.spacing) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAllAppcues(layout, style)
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
                layout: nil,
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
                layout: EC.Layout(spacing: 48,
                                  horizontalAlignment: "leading",
                                  paddingTop: 8,
                                  paddingLeading: 8,
                                  paddingBottom: 8,
                                  paddingTrailing: 8),
                style: EC.Style(backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
