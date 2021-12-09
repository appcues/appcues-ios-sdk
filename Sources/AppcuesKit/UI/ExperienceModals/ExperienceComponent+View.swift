//
//  ExperienceComponent+View.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension ExperienceComponent {

    @ViewBuilder var view: some View {
        switch self {
        case .pager(let model):
            AppcuesPager(model: model)
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
        case .spacer(let model):
            Spacer(minLength: CGFloat(model.spacing))
        }
    }
}

extension ExperienceComponent.ImageModel.IntrinsicSize {
    var aspectRatio: CGFloat {
        width / height
    }
}
