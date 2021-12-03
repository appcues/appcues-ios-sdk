//
//  AppcuesPager.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesPager: View {
    let model: ExperienceComponent.PagerModel

    @State private var currentPage = 0

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)
        let progressIndicatorStyle = AppcuesStyle(from: model.progress.style)

        let axis = Axis(string: model.axis) ?? .horizontal

        ZStack(alignment: progressIndicatorStyle.alignment) {
            PagerView(
                axis: axis,
                pages: model.items.map { $0.view },
                currentPage: $currentPage,
                infinite: model.infinite ?? false)
                .setupActions(viewModel.groupedActionHandlers(for: model.id))

            if model.progress.type == .dot {
                PageControl(numberOfPages: model.items.count, currentPage: $currentPage)
                    .frame(width: CGFloat(model.items.count * 18))
                    .pageIndicatorTintColor(UIColor(dynamicColor: model.progress.style?.backgroundColor))
                    .currentPageIndicatorTintColor(UIColor(dynamicColor: model.progress.style?.foregroundColor))
                    .applyInternalLayout(progressIndicatorStyle)
                    .applyBorderStyle(progressIndicatorStyle)
                    .applyExternalLayout(progressIndicatorStyle)
            }
        }
        .applyAllAppcues(style)
    }

}

#if DEBUG
internal struct AppcuesPagerPreview: PreviewProvider {

    static var previews: some View {
        Group {
            AppcuesPager(model: EC.PagerModel(
                id: UUID(),
                progress: EC.PagerProgressModel(type: .dot, style: nil),
                items: [
                    .column(EC.vstackHero),
                    .column(EC.vstackHero),
                    .column(EC.vstackHero)
                ],
                axis: nil,
                infinite: false,
                style: EC.Style(backgroundColor: "#333"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
