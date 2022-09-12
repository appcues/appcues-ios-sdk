//
//  ExperienceComponent+View.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
extension ExperienceComponent {

    @ViewBuilder var view: some View {
        switch self {
        case .stack(let model):
            AppcuesStack(model: model)
        case .box(let model):
            AppcuesBox(model: model)
        case .text(let model):
            AppcuesText(model: model)
        case .button(let model):
            AppcuesButton(model: model)
        case .image(let model):
            AppcuesImage(model: model)
        case .embed(let model):
            AppcuesEmbed(model: model)
        case .textInput(let model):
            AppcuesTextInput(model: model)
        case .spacer(let model):
            Spacer(minLength: CGFloat(model.spacing))
        }
    }
}

extension ExperienceComponent.IntrinsicSize {
    var aspectRatio: CGFloat {
        width / height
    }
}
