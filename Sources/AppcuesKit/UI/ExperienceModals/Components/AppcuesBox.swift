//
//  AppcuesBox.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesBox: View {
    let model: ExperienceComponent.BoxModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        ZStack(alignment: layout.alignment) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAllAppcues(layout, style)
    }
}

#if DEBUG
internal struct AppcuesBoxPreview: PreviewProvider {

    static var previews: some View {
        Group {
            AppcuesBox(model: EC.zstackHero)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesBox(model: EC.BoxModel(
                id: UUID(),
                items: [
                    .image(EC.imageBanner),
                    .text(EC.textTitle)
                ],
                layout: EC.Layout(verticalAlignment: "top", horizontalAlignment: "leading"),
                style: nil)
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
