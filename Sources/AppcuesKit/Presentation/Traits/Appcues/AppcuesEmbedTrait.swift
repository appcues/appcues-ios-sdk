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
        let style: ExperienceComponent.Style?
        // swiftlint:disable:next discouraged_optional_boolean
        let animated: Bool?
    }

    static let type = "@appcues/embed"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private weak var appcues: Appcues?

    // the title of the embed container
    let embedID: String
    private let style: ExperienceComponent.Style?
    private let animated: Bool

    // the view embedded somewhere in the customer application
    weak var embedView: AppcuesView?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.embedID = config.embedID
        self.animated = config.animated ?? false
        self.style = config.style
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(
            top: style?.paddingTop ?? 0,
            leading: style?.paddingLeading ?? 0,
            bottom: style?.paddingBottom ?? 0,
            trailing: style?.paddingTrailing ?? 0
        )
    }

    func createWrapper(around containerController: AppcuesExperienceContainerViewController) throws -> UIViewController {
        applyStyle(style, to: containerController)
        return containerController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        // no backdrop on embeds
    }

    func present(viewController: UIViewController, completion: (() -> Void)?) throws {
        self.embedView = appcues?.embedViews.allObjects.first { $0.embedID == embedID }

        guard let embedView = embedView else {
            throw AppcuesTraitError(description: "No embed view found")
        }

        guard embedView.subviews.isEmpty else {
            throw AppcuesTraitError(description: "Embed already in use")
        }

        let margins = NSDirectionalEdgeInsets(
            top: style?.marginTop ?? 0,
            leading: style?.marginLeading ?? 0,
            bottom: style?.marginBottom ?? 0,
            trailing: style?.marginTrailing ?? 0
        )

        embedView.embed(viewController, margins: margins, animated: animated, completion: completion)
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        embedView?.unembed(viewController, animated: animated, completion: completion)
    }

    private func applyStyle(_ style: ExperienceComponent.Style?, to container: UIViewController) {
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
