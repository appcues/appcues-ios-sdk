//
//  AppcuesTooltipTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-16.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTooltipTrait: AppcuesStepDecoratingTrait, AppcuesWrapperCreatingTrait, AppcuesPresentingTrait {
    struct Config: Decodable {
        // swiftlint:disable:next discouraged_optional_boolean
        let hidePointer: Bool?
        let pointerBase: Double?
        let pointerLength: Double?
        let pointerCornerRadius: Double?
        let style: ExperienceComponent.Style?
    }

    static let type = "@appcues/tooltip"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    let tooltipStyle: ExperienceComponent.Style?
    let themeStyle: ExperienceComponent.Style?
    let hidePointer: Bool
    let pointerSize: CGSize
    let pointerCornerRadius: CGFloat

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        let config = configuration.decode(Config.self)
        self.hidePointer = config?.hidePointer ?? false
        self.pointerSize = CGSize(width: config?.pointerBase ?? 16, height: config?.pointerLength ?? 8)
        self.pointerCornerRadius = config?.pointerCornerRadius ?? 0
        self.tooltipStyle = config?.style
        self.themeStyle = configuration.theme?["tooltip"]
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(paddingFrom: tooltipStyle)
    }

    func createWrapper(around containerController: AppcuesExperienceContainerViewController) throws -> UIViewController {
        let experienceWrapperViewController = ExperienceWrapperViewController<TooltipWrapperView>(wrapping: containerController)
        experienceWrapperViewController.configureStyle(tooltipStyle, themeStyle: themeStyle)
        experienceWrapperViewController.bodyView.pointerSize = hidePointer ? nil : pointerSize
        experienceWrapperViewController.bodyView.pointerCornerRadius = pointerCornerRadius

        if let preferredWidth = tooltipStyle?.width {
            experienceWrapperViewController.bodyView.preferredWidth = preferredWidth
        }
        // Ensure content isn't hidden by the tooltip pointer
        experienceWrapperViewController.bodyView.pointerInsetHandler = { insets in
            containerController.additionalSafeAreaInsets = insets
        }

        setHandler(wrapperController: experienceWrapperViewController, initial: true)

        return experienceWrapperViewController
    }

    // We want a non-animating handler until we have a targetRectangle value at which point we want to switch to an animating handler.
    // This ensure the first step in a group doesn't awkwardly animate from the no target bottom position.
    private func setHandler(wrapperController: ExperienceWrapperViewController<TooltipWrapperView>, initial: Bool) {
        metadataDelegate?.registerHandler(for: Self.type, animating: !initial) { [weak self] metadata in
            wrapperController.bodyView.preferredPosition = metadata["contentPreferredPosition"]
            wrapperController.bodyView.distanceFromTarget = metadata["contentDistanceFromTarget"] ?? 0
            wrapperController.bodyView.targetRectangle = metadata["targetRectangle"]

            if initial && wrapperController.bodyView.targetRectangle != nil {
                self?.setHandler(wrapperController: wrapperController, initial: false)
            }
        }
    }

    func getBackdrop(for wrapperController: UIViewController) -> UIView? {
        return (wrapperController as? ExperienceWrapperViewController<TooltipWrapperView>)?.bodyView.backdropView
    }

    func present(viewController: UIViewController, completion: (() -> Void)?) throws {
        guard let topViewController = UIApplication.shared.topViewController() else {
            throw AppcuesTraitError(description: "No top VC found")
        }

        topViewController.present(viewController, animated: true, completion: completion)
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        viewController.dismiss(animated: true, completion: completion)
    }
}
