//
//  AppcuesText.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesText: View {
    let model: ExperienceComponent.TextModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        Text(model.text)
            .applyTextStyle(style, text: model.text)
            .setupActions(on: viewModel, for: model)
            .applyAllAppcues(style)
            .fixedSize(horizontal: false, vertical: true)
    }
}
