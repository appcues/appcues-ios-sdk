//
//  AppcuesEmbedTrait.swift
//  AppcuesKit
//
//  Created by James Ellis on 8/18/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesEmbedTrait: AppcuesStepDecoratingTrait, AppcuesWrapperCreatingTrait, AppcuesPresentingTrait {

    struct Config: Decodable {
        let embedID: String
        let embedStyle: ExperienceComponent.Style?
        // swiftlint:disable:next discouraged_optional_boolean
        let animated: Bool?
    }

    static let type = "@appcues/embed"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    // the title of the embed container
    let embedID: String
    private let embedStyle: ExperienceComponent.Style?
    private let animated: Bool

    // the appcues experience content that is embedded
    private weak var experienceController: UIViewController?

    // the view embedded somewhere in the customer application
    weak var embedView: AppcuesView?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.embedID = config.embedID
        self.animated = config.animated ?? false
        self.embedStyle = config.embedStyle
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(
            top: embedStyle?.paddingTop ?? 0,
            leading: embedStyle?.paddingLeading ?? 0,
            bottom: embedStyle?.paddingBottom ?? 0,
            trailing: embedStyle?.paddingTrailing ?? 0
        )
    }

    func createWrapper(around containerController: AppcuesExperienceContainerViewController) throws -> UIViewController {
        experienceController = containerController
        applyStyle(to: containerController, embedStyle)
        return containerController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        // no backdrop on embeds
    }

    func present(viewController: UIViewController, completion: (() -> Void)?) throws {

        guard let embedView = embedView else {
            throw AppcuesTraitError(description: "No embed view found")
        }

        guard embedView.experienceController == nil else {
            throw AppcuesTraitError(description: "Embed already in use")
        }

        guard let experienceController = experienceController, experienceController.parent == nil else {
            throw AppcuesTraitError(description: "No valid experience to embed")
        }

        let margins = NSDirectionalEdgeInsets(
            top: embedStyle?.marginTop ?? 0,
            leading: embedStyle?.marginLeading ?? 0,
            bottom: embedStyle?.marginBottom ?? 0,
            trailing: embedStyle?.marginTrailing ?? 0
        )

        embedView.embed(experienceController, margins: margins, animated: animated)
        completion?()
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        embedView?.unembed(animated: animated)
        completion?()
    }

    private func applyStyle(to container: UIViewController, _ style: ExperienceComponent.Style?) {
        container.view.backgroundColor = UIColor(dynamicColor: style?.backgroundColor)
        container.view.layer.cornerRadius = style?.cornerRadius ?? 0
        container.view.layer.borderColor = UIColor(dynamicColor: style?.borderColor)?.cgColor
        if let borderWidth = CGFloat(style?.borderWidth) {
            container.view.layer.borderWidth = borderWidth
            container.view.layoutMargins = UIEdgeInsets(
                top: borderWidth,
                left: borderWidth,
                bottom: borderWidth,
                right: borderWidth
            )
        }
    }

}
