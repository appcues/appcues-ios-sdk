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
        id: UUID(),
        text: "This is some text with no style provided.",
        layout: nil,
        style: nil)

    static let textTitle = EC.TextModel(
        id: UUID(),
        text: "Hero Title 🚀",
        layout: nil,
        style: EC.Style(fontSize: 36, foregroundColor: "#fff"))

    static let textSubtitle = EC.TextModel(
        id: UUID(),
        text: "To infinity, and beyond!",
        layout: nil,
        style: EC.Style(foregroundColor: "#fff"))

    static let buttonPrimary = EC.ButtonModel(
        id: UUID(),
        text: "Primary Button",
        layout: EC.Layout.button,
        style: EC.Style.primaryButton)

    static let buttonSecondary = EC.ButtonModel(
        id: UUID(),
        text: "Secondary Button",
        layout: EC.Layout.button,
        style: EC.Style.secondaryButton)

    static let buttonCallToAction = EC.ButtonModel(
        id: UUID(),
        text: "Call to Action",
        layout: EC.Layout(paddingTop: 12, paddingLeading: 24, paddingBottom: 12, paddingTrailing: 24, marginTop: 30),
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
        id: UUID(),
        items: [
            .text(EC.textTitle),
            .text(EC.textSubtitle),
            .button(EC.buttonCallToAction)
        ],
        layout: EC.Layout(spacing: 12),
        style: nil)

    static let zstackHero = EC.ZStackModel(
        id: UUID(),
        items: [
            .image(EC.imageBanner),
            .vstack(EC.vstackHero)
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
        paddingTop: 12,
        paddingLeading: 24,
        paddingBottom: 12,
        paddingTrailing: 24
    )
}
#endif
