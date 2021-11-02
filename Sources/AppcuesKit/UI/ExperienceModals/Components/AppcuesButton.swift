//
//  AppcuesButton.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesButton: View {
    let model: ExperienceComponent.ButtonModel

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        Button(model.text) {
            print("tap")
        }
        .applyAppcues(layout, style)
    }
}

#if DEBUG
internal struct AppcuesButtonPreview: PreviewProvider {
    static var previews: some View {
        Group {
            AppcuesButton(model: EC.ButtonModel(
                text: "Default Button",
                layout: nil,
                style: nil)
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesButton(model: EC.buttonPrimary)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesButton(model: EC.buttonSecondary)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
