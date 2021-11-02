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

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        Text(model.text)
            .ifLet(style.alignment) { view, val in
                view.multilineTextAlignment(val)
            }
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
                text: "This is some text that wraps and is center aligned.",
                layout: EC.Layout(width: 100),
                style: EC.Style(alignment: "center"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesText(model: EC.TextModel(
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
