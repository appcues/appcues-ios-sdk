//
//  AppcuesButton.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesButton: View {
    let model: ExperienceComponent.ButtonModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        Button() {
            // handle tap in `.setupActions`
        } label: {
            model.content.view
                // If the button has a set width instead of sizing according to the content,
                // the content may need to be aligned within the the expanded space.
                // The `if` check is necessary since `maxWidth: .infinity` would blow things up
                // if there was no set width on the Button itself.
                .if(style.width != nil || style.fillWidth) { view in
                    view.frame(maxWidth: .infinity, alignment: Alignment(
                        vertical: model.content.style?.verticalAlignment,
                        horizontal: model.content.style?.horizontalAlignment
                    ) ?? .center)
                }
                // Applying the Button padding and frame to the label ensures the proper button highlight effect
                // on touchDown everywhere within the button frame.
                .applyInternalLayout(style)
        }
        .applyForegroundStyle(style)
        .applyBackgroundStyle(style)
        .applyBorderStyle(style)
        .applyExternalLayout(style)
        .setupActions(on: viewModel, for: model)
    }
}
