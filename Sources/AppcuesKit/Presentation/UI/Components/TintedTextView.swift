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

    // this is to support dynamic type
    // https://stackoverflow.com/a/70800548
    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        Text(textModel: model, skipColor: tintColor != nil, scaled: viewModel.enableTextScaling)
            .applyTextStyle(style, model: model)
            .setupActions(on: viewModel, for: model)
            .ifLet(tintColor) { view, val in
                view.foregroundColor(val)
            }
            .applyAllAppcues(style)
            .fixedSize(horizontal: false, vertical: true)
    }
}
