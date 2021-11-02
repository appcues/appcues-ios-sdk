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

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        ZStack(alignment: layout.alignment) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
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
                items: [
                    EC(model: .image(EC.imageBanner)),
                    EC(model: .text(EC.textTitle))
                ],
                layout: EC.Layout(alignment: "topLeading"),
                style: nil)
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
