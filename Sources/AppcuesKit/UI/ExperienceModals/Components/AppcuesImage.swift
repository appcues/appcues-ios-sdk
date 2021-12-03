//
//  AppcuesImage.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesImage: View {
    let model: ExperienceComponent.ImageModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel
    @Environment(\.imageCache) var imageCache: SessionImageCache

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        if let url = model.imageUrl {
            RemoteImage(url: url, cache: imageCache) {
                style.backgroundColor ?? Color(UIColor.secondarySystemBackground)
            }
            .ifLet(ContentMode(string: model.contentMode)) { view, val in
                view.aspectRatio(contentMode: val)
            }
            .clipped()
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyAllAppcues(style)
        } else {
            Image(systemName: model.symbolName ?? "")
                .clipped()
                .setupActions(viewModel.groupedActionHandlers(for: model.id))
                .applyAllAppcues(style)
        }
    }
}

#if DEBUG
internal struct AppcuesImagePreview: PreviewProvider {
    // swiftlint:disable:next force_unwrapping
    static let imageURL = URL(string: "https://res.cloudinary.com/dnjrorsut/image/upload/v1513187203/crx-assets/modal-slideout-hero-image.png")!
    static var previews: some View {
        Group {
            AppcuesImage(model: EC.imageSymbol)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesImage(model: EC.imageBanner)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()

            AppcuesImage(model: EC.ImageModel(
                imageUrl: imageURL,
                contentMode: "fit",
                style: EC.Style(height: 100, width: 100, backgroundColor: "#eee"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
