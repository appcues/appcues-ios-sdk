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
        switch model {
        case .pager(let model):
            AppcuesPager(id: id, model: model)
        case .vstack(let model):
            AppcuesVStack(id: id, model: model)
        case .hstack(let model):
            AppcuesHStack(id: id, model: model)
        case .zstack(let model):
            AppcuesZStack(id: id, model: model)
        case .text(let model):
            AppcuesText(id: id, model: model)
        case .button(let model):
            AppcuesButton(id: id, model: model)
        case .image(let model):
            AppcuesImage(id: id, model: model)
        case .spacer(let model):
            Spacer(minLength: CGFloat(model.layout?.spacing))
        }
    }
}
