//
//  AppcuesEmbeddedTrait.swift
//  AppcuesKit
//
//  Created by James Ellis on 8/18/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesEmbeddedTrait: AppcuesStepDecoratingTrait, AppcuesWrapperCreatingTrait, AppcuesPresentingTrait {

    struct Config: Decodable {
        let frameID: String
        let style: ExperienceComponent.Style?
        let animation: AnimationOption?
    }

    static let type = "@appcues/embedded"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private weak var appcues: Appcues?

    // the title of the embed container
    private let frameID: String
    private let style: ExperienceComponent.Style?
    private let animation: AnimationOption

    // the view embedded somewhere in the customer application
    weak var embedView: AppcuesFrame?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.frameID = config.frameID
        self.animation = config.animation ?? .none
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
        let experienceRenderer = appcues?.container.resolve(ExperienceRendering.self)

        self.embedView = experienceRenderer?.owner(forContext: .embed(frameID: frameID)) as? AppcuesFrame

        guard let embedView = embedView else {
            throw AppcuesTraitError(description: "No embed view with ID \(frameID) found")
        }

        let margins = NSDirectionalEdgeInsets(
            top: style?.marginTop ?? 0,
            leading: style?.marginLeading ?? 0,
            bottom: style?.marginBottom ?? 0,
            trailing: style?.marginTrailing ?? 0
        )

        embedView.embed(viewController, margins: margins, animated: animation == .fade, completion: completion)
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        embedView?.unembed(viewController, animated: animation == .fade, completion: completion)
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

@available(iOS 13.0, *)
extension AppcuesEmbeddedTrait {
    enum AnimationOption: String, Decodable {
        case none
        case fade
    }
}
