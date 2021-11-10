//
//  AppcuesZStack.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesZStack: View {
    let model: ExperienceComponent.ZStackModel

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
        .applyAppcues(layout, style)
    }
}

#if DEBUG
internal struct AppcuesZStackPreview: PreviewProvider {

    static var previews: some View {
        Group {
            AppcuesZStack(model: EC.zstackHero)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesZStack(model: EC.ZStackModel(
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
