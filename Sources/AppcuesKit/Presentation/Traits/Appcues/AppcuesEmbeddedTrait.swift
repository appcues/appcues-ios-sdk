//
//  AppcuesEmbeddedTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2023-06-13.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesEmbeddedTrait: AppcuesStepDecoratingTrait, AppcuesContainerDecoratingTrait, AppcuesPresentingTrait {

    struct Config: Decodable {
        let frameID: String
        let style: ExperienceComponent.Style?
        let transition: AppcuesFrameView.Transition?
    }

    static let type = "@appcues/embedded"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private weak var appcues: Appcues?

    private let frameID: String
    private let transition: AppcuesFrameView.Transition
    private let style: ExperienceComponent.Style?

    // The view embedded in the customer application
    weak var embedView: AppcuesFrameView?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.frameID = config.frameID
        self.transition = config.transition ?? .none
        self.style = config.style
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(paddingFrom: style)
    }

    func decorate(containerController: AppcuesExperienceContainerViewController) throws {
        applyStyle(style, to: containerController)
    }

    func undecorate(containerController: AppcuesExperienceContainerViewController) throws {
        applyStyle(nil, to: containerController)
    }

    func present(viewController: UIViewController, completion: (() -> Void)?) throws {
        let experienceRenderer = appcues?.container.resolve(ExperienceRendering.self)

        self.embedView = experienceRenderer?.owner(forContext: .embed(frameID: frameID)) as? AppcuesFrameView

        guard let embedView = embedView else {
            throw AppcuesTraitError(description: "No AppcuesFrameView registered for ID \(frameID)")
        }

        let margins = NSDirectionalEdgeInsets(marginFrom: style)
        embedView.embed(viewController, margins: margins, transition: transition, completion: completion)
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        embedView?.unembed(viewController, transition: transition, completion: completion)
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
