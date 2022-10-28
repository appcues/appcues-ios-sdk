//
//  TintedTextView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-10-03.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct TintedTextView: View {
    let model: ExperienceComponent.TextModel
    let tintColor: Color?

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        Text(model.text)
            .applyTextStyle(style, text: model.text)
            .setupActions(on: viewModel, for: model)
            .ifLet(tintColor) { view, val in
                view.foregroundColor(val)
            }
            .applyAllAppcues(style)
            .fixedSize(horizontal: false, vertical: true)
    }
}
