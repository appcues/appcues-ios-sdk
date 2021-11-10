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
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        Text(model.text)
            .ifLet(style.letterSpacing) { view, val in
                view.kerning(val)
            }
            .ifLet(style.textAlignment) { view, val in
                view.multilineTextAlignment(val)
            }
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyAppcues(layout, style)
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
                layout: EC.Layout(width: 100),
                style: EC.Style(textAlignment: "center"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesText(model: EC.TextModel(
                id: UUID(),
                text: "Heading Sized Text",
                layout: nil,
                style: EC.Style(fontSize: 36, foregroundColor: "#f00"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
