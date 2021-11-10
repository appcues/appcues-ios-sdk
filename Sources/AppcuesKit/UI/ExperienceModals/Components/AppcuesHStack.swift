//
//  AppcuesHStack.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesHStack: View {
    let model: ExperienceComponent.HStackModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        HStack(alignment: layout.verticalAlignment, spacing: CGFloat(model.layout?.spacing)) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAppcues(layout, style)
    }
}

#if DEBUG
internal struct AppcuesHStackPreview: PreviewProvider {

    static var previews: some View {
        Group {
            AppcuesHStack(model: EC.HStackModel(
                id: UUID(),
                items: [
                    .image(EC.imageSymbol),
                    .text(EC.textPlain)
                ],
                layout: nil,
                style: EC.Style(backgroundColor: "#eee"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
