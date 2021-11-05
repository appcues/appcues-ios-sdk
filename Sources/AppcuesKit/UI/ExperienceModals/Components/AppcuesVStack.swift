//
//  AppcuesVStack.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesVStack: View {
    let id: UUID
    let model: ExperienceComponent.VStackModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        VStack(alignment: layout.horizontalAlignment, spacing: layout.spacing) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: id))
        .applyAppcues(layout, style)
    }
}

#if DEBUG
internal struct AppcuesVStackPreview: PreviewProvider {

    static var previews: some View {
        Group {
            AppcuesVStack(id: UUID(), model: EC.VStackModel(
                items: [
                    EC(model: .text(EC.textTitle)),
                    EC(model: .text(EC.textSubtitle)),
                    EC(model: .button(EC.buttonPrimary))
                ],
                layout: nil,
                style: EC.Style(backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesVStack(id: UUID(), model: EC.VStackModel(
                items: [
                    EC(model: .text(EC.textTitle)),
                    EC(model: .text(EC.textSubtitle)),
                    EC(model: .button(EC.buttonPrimary))
                ],
                layout: EC.Layout(spacing: 48, alignment: "leading", padding: "8,8,8,8"),
                style: EC.Style(backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
