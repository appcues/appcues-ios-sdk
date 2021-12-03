//
//  AppcuesText.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesText: View {
    let model: ExperienceComponent.TextModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        Text(model.text)
            .applyTextStyle(style)
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyAllAppcues(style)
    }
}

#if DEBUG
internal struct AppcuesTextPreview: PreviewProvider {
    static var previews: some View {
        Group {
            AppcuesText(model: EC.textPlain)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesText(model: EC.TextModel(
                id: UUID(),
                text: "This is some text that wraps and is center aligned.",
                style: EC.Style(width: 100, textAlignment: "center"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesText(model: EC.TextModel(
                id: UUID(),
                text: "Heading Sized Text",
                style: EC.Style(fontSize: 36, foregroundColor: "#f00"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
