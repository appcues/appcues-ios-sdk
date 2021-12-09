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
            .setupActions(viewModel.groupedActionHandlers(for: model.id))
            .applyForegroundStyle(style)
            // set the aspect ratio before applying frame sizing
            .ifLet(ContentMode(string: model.contentMode)) { view, val in
                view.aspectRatio(model.intrinsicSize?.aspectRatio, contentMode: val)
            }
            .applyInternalLayout(style)
            // clip before adding shadows
            .clipped()
            .applyBackgroundStyle(style)
            .applyBorderStyle(style)
            .applyExternalLayout(style)
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
                intrinsicSize: EC.ImageModel.IntrinsicSize(width: 1_920, height: 1_280),
                style: EC.Style(height: 100, width: 100, backgroundColor: "#eee"))
            )
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif
