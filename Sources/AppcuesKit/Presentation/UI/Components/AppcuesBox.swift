//
//  AppcuesBox.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesBox: View {
    let model: ExperienceComponent.BoxModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        ZStack(alignment: style.alignment) {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .setupActions(viewModel.groupedActionHandlers(for: model.id))
        .applyAllAppcues(style)
    }
}
