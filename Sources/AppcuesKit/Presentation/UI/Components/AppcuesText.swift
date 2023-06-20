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

    // this is to support dynamic type
    // https://stackoverflow.com/a/70800548
    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        Text(textModel: model)
            .applyTextStyle(style, model: model)
            .setupActions(on: viewModel, for: model)
            .applyAllAppcues(style)
            .fixedSize(horizontal: false, vertical: true)
    }
}

@available(iOS 13.0, *)
extension Text {
    init(textModel: ExperienceComponent.TextModel, skipColor: Bool = false) {
        self.init("")

        // Note: a ViewBuilder approach here doesn't work because the requirement that we operate strictly on `Text`
        // and not `some View` for concatenation to work. Therefore we work with the struct directly.
        textModel.spans.forEach { span in
            var text = Text(span.text)

            if let font = Font(
                name: span.style?.fontName ?? textModel.style?.fontName,
                size: span.style?.fontSize ?? textModel.style?.fontSize ?? UIFont.labelFontSize
            ) {
                text = text.font(font)
            }

            if !skipColor, let foregroundColor = Color(dynamicColor: span.style?.foregroundColor) {
                text = text.foregroundColor(foregroundColor)
            }

            if let kerning = span.style?.letterSpacing {
                text = text.kerning(kerning)
            }

            // A shorthand operator with `Text` doesn't compile
            // swiftlint:disable:next shorthand_operator
            self = self + text
        }
    }
}
