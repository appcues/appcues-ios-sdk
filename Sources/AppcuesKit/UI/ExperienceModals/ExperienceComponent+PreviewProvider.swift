//
//  ExperienceComponent+PreviewProvider.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

// Shortcuts for usage in PreviewProvider's

#if DEBUG
// swiftlint:disable:next type_name
internal typealias EC = ExperienceComponent

extension ExperienceComponent {
    static let textPlain = TextModel(
        id: UUID(),
        text: "This is some text with no style provided.",
        style: nil)

    static let textTitle = TextModel(
        id: UUID(),
        text: "Hero Title 🚀",
        style: EC.Style(fontSize: 36, foregroundColor: "#fff"))

    static let textSubtitle = TextModel(
        id: UUID(),
        text: "To infinity, and beyond!",
        style: EC.Style(foregroundColor: "#fff"))

    static let buttonPrimary = ButtonModel(
        id: UUID(),
        text: "Primary Button",
        style: Style.primaryButton)

    static let buttonSecondary = ButtonModel(
        id: UUID(),
        text: "Secondary Button",
        style: Style.secondaryButton)

    static let buttonCallToAction = ButtonModel(
        id: UUID(),
        text: "Call to Action",
        style: Style.primaryButton)

    static let imageSymbol = ImageModel(
        symbolName: "star.circle",
        style: Style(fontSize: 48, foregroundColor: "#FF5290"))

    static let imageBanner = ImageModel(
        imageUrl: AppcuesImagePreview.imageURL,
        contentMode: "fill",
        intrinsicSize: IntrinsicSize(width: 1_920, height: 1_280),
        style: Style(height: 300, width: 370))

    static let embedVideo = EmbedModel(
        id: UUID(),
        // swiftlint:disable:next line_length
        embed: "<script src=\"https://fast.wistia.com/embed/medias/41580cljhd.jsonp\" async></script><script src=\"https://fast.wistia.com/assets/external/E-v1.js\" async></script><div class=\"wistia_embed wistia_async_41580cljhd fitStrategy=fill  smallPlayButton=false playbar=false autoPlay=true settingsControl=false fullscreenButton=false \"></div>",
        intrinsicSize: IntrinsicSize(width: 16, height: 9),
        style: Style(height: 200))

    static let vstackHero = StackModel(
        id: UUID(),
        orientation: .vertical,
        distribution: .center,
        spacing: 12,
        items: [
            .text(textTitle),
            .text(textSubtitle),
            .button(buttonCallToAction)
        ],
        style: nil)

    static let zstackHero = BoxModel(
        id: UUID(),
        items: [
            .image(imageBanner),
            .stack(vstackHero)
        ],
        style: nil)
}

extension ExperienceComponent.Style {
    static let primaryButton = EC.Style(
        paddingTop: 12,
        paddingLeading: 24,
        paddingBottom: 12,
        paddingTrailing: 24,
        foregroundColor: "#fff",
        backgroundColor: "#5C5CFF",
        cornerRadius: 8)

    static let secondaryButton = EC.Style(
        paddingTop: 12,
        paddingLeading: 24,
        paddingBottom: 12,
        paddingTrailing: 24,
        foregroundColor: "#5C5CFF",
        cornerRadius: 8,
        borderColor: "#5C5CFF",
        borderWidth: 1)
}
#endif
