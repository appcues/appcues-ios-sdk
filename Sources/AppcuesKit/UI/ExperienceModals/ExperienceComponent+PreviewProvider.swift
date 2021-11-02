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
    static let textPlain = EC.TextModel(
        text: "This is some text with no style provided.",
        layout: nil,
        style: nil)

    static let textTitle = EC.TextModel(
        text: "Hero Title 🚀",
        layout: nil,
        style: EC.Style(fontSize: 36, foregroundColor: "#fff"))

    static let textSubtitle = EC.TextModel(
        text: "To infinity, and beyond!",
        layout: nil,
        style: EC.Style(foregroundColor: "#fff"))

    static let buttonPrimary = EC.ButtonModel(
        text: "Primary Button",
        layout: EC.Layout.button,
        style: EC.Style.primaryButton)

    static let buttonSecondary = EC.ButtonModel(
        text: "Secondary Button",
        layout: EC.Layout.button,
        style: EC.Style.secondaryButton)

    static let buttonCallToAction = EC.ButtonModel(
        text: "Call to Action",
        layout: EC.Layout(padding: "12, 24, 12, 24", margin: "30,0,0,0"),
        style: EC.Style.primaryButton)

    static let imageSymbol = EC.ImageModel(
        symbolName: "star.circle",
        layout: nil,
        style: EC.Style(fontSize: 48, foregroundColor: "#FF5290"))

    static let imageBanner = ExperienceComponent.ImageModel(
        imageUrl: AppcuesImagePreview.imageURL,
        contentMode: "fill",
        layout: ExperienceComponent.Layout(height: 300, width: 370),
        style: nil)

    static let vstackHero = EC.VStackModel(
        items: [
            EC(model: .text(EC.textTitle)),
            EC(model: .text(EC.textSubtitle)),
            EC(model: .button(EC.buttonCallToAction))
        ],
        layout: EC.Layout(spacing: 12),
        style: nil)

    static let zstackHero = EC.ZStackModel(
        items: [
            EC(model: .image(EC.imageBanner)),
            EC(model: .vstack(EC.vstackHero))
        ],
        layout: nil,
        style: nil)
}

extension ExperienceComponent.Style {
    static let primaryButton = EC.Style(
        foregroundColor: "#fff",
        backgroundColor: "#5C5CFF",
        cornerRadius: 8)

    static let secondaryButton = EC.Style(
        foregroundColor: "#5C5CFF",
        cornerRadius: 8,
        borderColor: "#5C5CFF",
        borderWidth: 1)
}

extension ExperienceComponent.Layout {
    static let button = EC.Layout(
        padding: "12, 24, 12, 24"
    )
}
#endif
