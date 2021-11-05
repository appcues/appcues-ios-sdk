//
//  AppcuesPager.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesPager: View {
    let id: UUID
    let model: ExperienceComponent.PagerModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        TabView {
            ForEach(model.items) {
                AnyView($0.view)
            }
        }
        .modifier(PagerViewModifier())
        .setupActions(viewModel.groupedActionHandlers(for: id))
        .applyAppcues(layout, style)
    }

}

#if DEBUG
internal struct AppcuesPagerPreview: PreviewProvider {

    static var previews: some View {
        Group {
            AppcuesPager(id: UUID(), model: EC.PagerModel(
                items: [
                    EC(model: .vstack(EC.vstackHero)),
                    EC(model: .vstack(EC.vstackHero)),
                    EC(model: .vstack(EC.vstackHero))
                ],
                layout: nil,
                style: EC.Style(backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
