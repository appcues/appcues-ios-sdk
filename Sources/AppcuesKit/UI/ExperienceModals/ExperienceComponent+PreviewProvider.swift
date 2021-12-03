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
        style: nil)

    static let textTitle = EC.TextModel(
        id: UUID(),
        text: "Hero Title 🚀",
        style: EC.Style(fontSize: 36, foregroundColor: "#fff"))

    static let textSubtitle = EC.TextModel(
        id: UUID(),
        text: "To infinity, and beyond!",
        style: EC.Style(foregroundColor: "#fff"))

    static let buttonPrimary = EC.ButtonModel(
        id: UUID(),
        text: "Primary Button",
        style: EC.Style.primaryButton)

    static let buttonSecondary = EC.ButtonModel(
        id: UUID(),
        text: "Secondary Button",
        style: EC.Style.secondaryButton)

    static let buttonCallToAction = EC.ButtonModel(
        id: UUID(),
        text: "Call to Action",
        style: EC.Style.primaryButton)

    static let imageSymbol = EC.ImageModel(
        symbolName: "star.circle",
        style: EC.Style(fontSize: 48, foregroundColor: "#FF5290"))

    static let imageBanner = ExperienceComponent.ImageModel(
        imageUrl: AppcuesImagePreview.imageURL,
        contentMode: "fill",
        style: ExperienceComponent.Style(height: 300, width: 370))

    static let vstackHero = EC.StackModel(
        id: UUID(),
        orientation: .vertical,
        items: [
            .text(EC.textTitle),
            .text(EC.textSubtitle),
            .button(EC.buttonCallToAction)
        ],
        style: EC.Style(spacing: 12))

    static let zstackHero = EC.BoxModel(
        id: UUID(),
        items: [
            .image(EC.imageBanner),
            .stack(EC.vstackHero)
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
