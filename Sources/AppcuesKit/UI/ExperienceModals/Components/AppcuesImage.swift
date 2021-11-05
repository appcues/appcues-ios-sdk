//
//  AppcuesImage.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesImage: View {
    let id: UUID
    let model: ExperienceComponent.ImageModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let layout = AppcuesLayout(from: model.layout)
        let style = AppcuesStyle(from: model.style)

        if let url = model.imageUrl {
            RemoteImage(url: url) {
                Color(UIColor.secondarySystemBackground)
            }
            .ifLet(ContentMode(string: model.contentMode)) { view, val in
                view.aspectRatio(contentMode: val)
            }
            .setupActions(viewModel.groupedActionHandlers(for: id))
            .applyAppcues(layout, style)
            .clipped()
        } else {
            Image(systemName: model.symbolName ?? "")
                .setupActions(viewModel.groupedActionHandlers(for: id))
                .applyAppcues(layout, style)
                .clipped()
        }
    }
}

#if DEBUG
internal struct AppcuesImagePreview: PreviewProvider {
    // swiftlint:disable:next force_unwrapping
    static let imageURL = URL(string: "https://res.cloudinary.com/dnjrorsut/image/upload/v1513187203/crx-assets/modal-slideout-hero-image.png")!
    static var previews: some View {
        Group {
            AppcuesImage(id: UUID(), model: EC.imageSymbol)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesImage(id: UUID(), model: EC.imageBanner)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesImage(id: UUID(), model: EC.ImageModel(
                imageUrl: imageURL,
                contentMode: "fit",
                layout: EC.Layout(height: 100, width: 100),
                style: EC.Style(backgroundColor: "#eee"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
