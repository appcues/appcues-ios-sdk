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
                // Applying the Button padding and frame to the label ensures the proper button highlight effect
                // on touchDown everywhere within the button frame.
                .applyInternalLayout(style)
        }
        .applyForegroundStyle(style)
        .applyBackgroundStyle(style)
        .applyBorderStyle(style)
        .applyExternalLayout(style)
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
    }
}
