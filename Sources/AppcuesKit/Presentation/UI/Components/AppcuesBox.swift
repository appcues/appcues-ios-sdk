//
//  AppcuesBox.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesBox: View {
    let model: ExperienceComponent.BoxModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        ZStack(alignment: style.alignment) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAllAppcues(style)
    }
}

#if DEBUG
@available(iOS 13.0, *)
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
                style: EC.Style(verticalAlignment: "top", horizontalAlignment: "leading"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
