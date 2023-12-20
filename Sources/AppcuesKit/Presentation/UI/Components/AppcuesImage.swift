//
//  AppcuesImage.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesImage: View {
    let model: ExperienceComponent.ImageModel
    private let transformedURL: URL

    @EnvironmentObject var viewModel: ExperienceStepViewModel
    @Environment(\.imageCache) var imageCache: SessionImageCache

    var body: some View {
        let contentMode = ContentMode(string: model.contentMode)

        // special case for images - need to pass the content mode and aspectRatio values so we can properly
        // set the borderInsets to use for this view
        let style = AppcuesStyle(from: model.style, theme: viewModel.theme, contentMode: contentMode, aspectRatio: model.intrinsicSize?.aspectRatio)

        content(placeholder: style.backgroundColor)
            .ifLet(model.accessibilityLabel) { view, val in
                view.accessibility(label: Text(val))
            }
            // allocate space for any border that will be applied below
            .padding(style.borderInset)
            .setupActions(on: viewModel, for: model)
            .applyForegroundStyle(style)
            // set the aspect ratio before applying frame sizing
            .ifLet(ContentMode(string: model.contentMode)) { view, val in
                view.aspectRatio(model.intrinsicSize?.aspectRatio, contentMode: val)
            }
            .applyInternalLayout(style)

            // clip before adding shadows
            .clipped()
            .applyBorderStyle(style)
            .applyBackgroundStyle(style)
            .applyCornerRadius(style)
            .applyShadow(style)
            .applyExternalLayout(style)
    }

    internal init(model: ExperienceComponent.ImageModel) {
        self.model = model

        // Setting this in the init to avoid recomputing it more frequently than necessary.
        self.transformedURL = model.imageUrl.transformImage(width: model.style?.width, height: model.style?.height)
    }

    @ViewBuilder
    private func content(placeholder: Color?) -> some View {
        if model.imageUrl.scheme == "sf-symbol" {
            Image(systemName: model.imageUrl.host ?? "")
        } else {
            RemoteImage(url: transformedURL, cache: imageCache) {
                if let blurImage = Image(blurHash: model.blurHash) {
                    blurImage.resizable()
                } else {
                    placeholder ?? Color.clear
                }
            }
        }
    }
}

private extension URL {

    /// Transforms an image URL to one with the best chance of rendering.
    func transformImage(width: Double? = nil, height: Double? = nil) -> URL {
        // Note: we're not specifically checking for Cloudinary in the URL because there's no functional
        // difference between a non-renderable image and a 404 caused by transforming a non-Cloudinary URL.
        if pathExtension == "svg" {
            return transformSVG(components: URLComponents(url: self, resolvingAgainstBaseURL: false), width: width, height: height) ?? self
        }

        return self
    }

    /// Converts a URL like https://res.cloudinary.com/xyz/image/upload/v123/000/abc.svg to
    /// https://res.cloudinary.com/xyz/image/upload/h_600,c_scale/v123/000/abc.png
    private func transformSVG(components: URLComponents?, width: Double? = nil, height: Double? = nil) -> URL? {
        guard var components = components else { return self }

        // Replace .svg in the path extension with .png
        let options: String.CompareOptions = [.backwards, .caseInsensitive]
        guard let range = components.path.range(of: ".svg", options: options, range: nil, locale: nil) else { return self }
        components.path = components.path.replacingCharacters(in: range, with: ".png")

        // Scale the png to the right size so it appears crisp like a vector would.
        let scale: CGFloat = UIScreen.main.scale
        var parts = components.path.split(separator: "/")
        if parts.count == 6, parts[2] == "upload" {
            if let width = width {
                // An integer scale value represents a fixed pixel size.
                parts.insert("w_\(Int(width * scale)),c_scale", at: 3)
            } else if let height = height {
                parts.insert("h_\(Int(height * scale)),c_scale", at: 3)
            } else {
                // If no fixed size, scale the default SVG size by the screen density.
                // A decimal scale value represents a percentage.
                parts.insert("w_\(scale),c_scale", at: 3)
            }
        }
        components.path = "/" + parts.joined(separator: "/")

        return components.url
    }
}
