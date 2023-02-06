//
//  AppcuesTooltipTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-16.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTooltipTrait: StepDecoratingTrait, WrapperCreatingTrait, PresentingTrait {
    struct Config: Decodable {
        // swiftlint:disable:next discouraged_optional_boolean
        let hidePointer: Bool?
        let pointerBase: Double?
        let pointerLength: Double?
        let style: ExperienceComponent.Style?
    }

    static let type = "@appcues/tooltip"

    weak var metadataDelegate: TraitMetadataDelegate?

    let tooltipStyle: ExperienceComponent.Style?
    let hidePointer: Bool
    let pointerSize: CGSize

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.hidePointer = config.hidePointer ?? false
        self.pointerSize = CGSize(width: config.pointerBase ?? 16, height: config.pointerLength ?? 8)
        self.tooltipStyle = config.style
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(
            top: tooltipStyle?.paddingTop ?? 0,
            leading: tooltipStyle?.paddingLeading ?? 0,
            bottom: tooltipStyle?.paddingBottom ?? 0,
            trailing: tooltipStyle?.paddingTrailing ?? 0)
    }

    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
        let experienceWrapperViewController = ExperienceWrapperViewController<TooltipWrapperView>(wrapping: containerController)
        experienceWrapperViewController.configureStyle(tooltipStyle)
        experienceWrapperViewController.bodyView.pointerSize = hidePointer ? nil : pointerSize
        if let preferredWidth = tooltipStyle?.width {
            experienceWrapperViewController.bodyView.preferredWidth = preferredWidth
        }
        // Ensure content isnt hidden by the tooltip pointer
        experienceWrapperViewController.bodyView.pointerInsetHandler = { insets in
            containerController.additionalSafeAreaInsets = insets
        }

        metadataDelegate?.registerHandler(for: Self.type, animating: true) { metadata in
            experienceWrapperViewController.bodyView.preferredPosition = metadata["contentPreferredPosition"]
            experienceWrapperViewController.bodyView.distanceFromTarget = metadata["contentDistanceFromTarget"] ?? 0
            experienceWrapperViewController.bodyView.targetRectangle = metadata["targetRectangle"]
        }

        return experienceWrapperViewController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        wrapperController.view.insertSubview(backdropView, at: 0)
        backdropView.pin(to: wrapperController.view)
    }

    func present(viewController: UIViewController, completion: (() -> Void)?) throws {
        guard let topViewController = UIApplication.shared.topViewController() else {
            throw TraitError(description: "No top VC found")
        }

        topViewController.present(viewController, animated: true, completion: completion)
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        viewController.dismiss(animated: true, completion: completion)
    }
}
