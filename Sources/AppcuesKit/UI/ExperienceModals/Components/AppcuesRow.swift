//
//  AppcuesRow.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesRow: View {
    let model: ExperienceComponent.RowModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        HStack(alignment: style.verticalAlignment, spacing: style.spacing) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAllAppcues(style)
    }
}

#if DEBUG
internal struct AppcuesRowPreview: PreviewProvider {

    static var previews: some View {
        Group {
            AppcuesRow(model: EC.RowModel(
                id: UUID(),
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
