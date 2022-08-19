//
//  AppcuesEmbedTrait.swift
//  AppcuesKit
//
//  Created by James Ellis on 8/18/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesEmbedTrait: StepDecoratingTrait, WrapperCreatingTrait, PresentingTrait {

    static let type = "@appcues/embed"

    private let embedStyle: ExperienceComponent.Style?
    private let animated: Bool

    // the appcues experience content that is embedded
    private weak var experienceController: UIViewController?

    // the title of the embed container
    var embedId: String

    // the view embedded somewhere in the customer application
    weak var embedView: AppcuesView?

    required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
        if let embedId = config?["embedId"] as? String {
            self.embedId = embedId
        } else {
            return nil
        }

        self.animated = (config?["animated"] as? Bool) ?? false
        self.embedStyle = config?["style", decodedAs: ExperienceComponent.Style.self]
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(
            top: embedStyle?.paddingTop ?? 0,
            leading: embedStyle?.paddingLeading ?? 0,
            bottom: embedStyle?.paddingBottom ?? 0,
            trailing: embedStyle?.paddingTrailing ?? 0)
    }

    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
        // should throw at this point if we don't have an embedViewController to use?
        experienceController = containerController

        if let backgroundColor = UIColor(dynamicColor: embedStyle?.backgroundColor) {
            containerController.view.backgroundColor = backgroundColor
        }

        containerController.view.clipsToBounds = true

        containerController.view.backgroundColor = UIColor(dynamicColor: embedStyle?.backgroundColor)
        containerController.view.layer.cornerRadius = embedStyle?.cornerRadius ?? 0

        containerController.view.layer.borderColor = UIColor(dynamicColor: embedStyle?.borderColor)?.cgColor
        containerController.view.layer.borderWidth = CGFloat(embedStyle?.borderWidth) ?? 0

        // containerController.view.shadowLayer = CAShapeLayer(shadowModel: embedStyle?.shadow)

        return containerController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        // no backdrop on embeds
    }

    func present(viewController: UIViewController, completion: (() -> Void)?) throws {

        guard let embedView = embedView else {
            throw TraitError(description: "No embed view found")
        }

        guard embedView.experienceController == nil else {
            throw TraitError(description: "Embed already in use")
        }

        guard let experienceController = experienceController, experienceController.parent == nil else {
            throw TraitError(description: "No valid experience to embed")
        }

        let margins = NSDirectionalEdgeInsets(
            top: embedStyle?.marginTop ?? 0,
            leading: embedStyle?.marginLeading ?? 0,
            bottom: embedStyle?.marginBottom ?? 0,
            trailing: embedStyle?.marginTrailing ?? 0)

        embedView.embed(experienceController, margins: margins, animated: animated)
        completion?()
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        embedView?.unembed(animated: animated)
        completion?()
    }
}
