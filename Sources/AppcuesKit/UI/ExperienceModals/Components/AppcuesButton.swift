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

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        Button() {
            // handle tap in `.setupActions`
        } label: {
            model.content.view
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAllAppcues(style)
    }
}

#if DEBUG
internal struct AppcuesButtonPreview: PreviewProvider {
    static var previews: some View {
        Group {
            AppcuesButton(model: EC.ButtonModel(
                id: UUID(),
                content: ExperienceComponent.text(ExperienceComponent.TextModel(id: UUID(), text: "Default Button", style: nil)),
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
