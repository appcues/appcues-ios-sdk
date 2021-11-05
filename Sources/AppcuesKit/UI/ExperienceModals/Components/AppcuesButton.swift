//
//  AppcuesButton.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesButton: View {
    let id: UUID
    let model: ExperienceComponent.ButtonModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        Button() {
            // handle tap in `.setupActions`
        } label: {
            // TODO: Layout the layout and style maybe should be applied on the text here?
            // Otherwise the button tap target seems to small when there's padding/background? Need to investigate.
            Text(model.text)
        }
        .setupActions(viewModel.groupedActionHandlers(for: id))
        .applyAppcues(layout, style)
    }
}

#if DEBUG
internal struct AppcuesButtonPreview: PreviewProvider {
    static var previews: some View {
        Group {
            AppcuesButton(id: UUID(), model: EC.ButtonModel(
                text: "Default Button",
                layout: nil,
                style: nil)
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesButton(id: UUID(), model: EC.buttonPrimary)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesButton(id: UUID(), model: EC.buttonSecondary)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
