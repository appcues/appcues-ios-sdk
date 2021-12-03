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
        case .column(let model):
            AppcuesColumn(model: model)
        case .row(let model):
            AppcuesRow(model: model)
        case .box(let model):
            AppcuesBox(model: model)
        case .text(let model):
            AppcuesText(model: model)
        case .button(let model):
            AppcuesButton(model: model)
        case .image(let model):
            AppcuesImage(model: model)
        case .spacer(let model):
            Spacer(minLength: CGFloat(model.style?.spacing))
        }
    }
}
