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
        case .vstack(let model):
            AppcuesVStack(model: model)
        case .hstack(let model):
            AppcuesHStack(model: model)
        case .zstack(let model):
            AppcuesZStack(model: model)
        case .text(let model):
            AppcuesText(model: model)
        case .button(let model):
            AppcuesButton(model: model)
        case .image(let model):
            AppcuesImage(model: model)
        case .spacer(let model):
            Spacer(minLength: CGFloat(model.layout?.spacing))
        }
    }
}
