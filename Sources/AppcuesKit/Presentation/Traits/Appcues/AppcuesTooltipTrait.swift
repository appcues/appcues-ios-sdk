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
        let preferredPosition: TooltipPosition?
        let hidePointer: Bool?
        let pointerBase: Double?
        let pointerLength: Double?
        let distanceFromTarget: Double?
        let style: ExperienceComponent.Style?
    }

    static let type = "@appcues/tooltip"

    weak var metadataDelegate: TraitMetadataDelegate?

    let tooltipStyle: ExperienceComponent.Style?
    let preferredPosition: TooltipPosition?
    let hidePointer: Bool
    let pointerSize: CGSize
    let distanceFromTarget: CGFloat

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.preferredPosition = config.preferredPosition
        self.hidePointer = config.hidePointer ?? false
        self.pointerSize = CGSize(width: config.pointerBase ?? 16, height: config.pointerLength ?? 8)
        self.tooltipStyle = config.style
        self.distanceFromTarget = config.distanceFromTarget ?? 0
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
        let dialogWrapperViewController = ExperienceWrapperViewController<TooltipWrapperView>(wrapping: containerController)
        dialogWrapperViewController.configureStyle(tooltipStyle)
        dialogWrapperViewController.bodyView.preferredPosition = preferredPosition
        dialogWrapperViewController.bodyView.pointerSize = hidePointer ? nil : pointerSize
        dialogWrapperViewController.bodyView.distanceFromTarget = distanceFromTarget
        if let preferredWidth = tooltipStyle?.width {
            dialogWrapperViewController.bodyView.preferredWidth = preferredWidth
        }
        // Ensure content isnt hidden by the tooltip pointer
        dialogWrapperViewController.bodyView.pointerInsetHandler = { insets in
            containerController.additionalSafeAreaInsets = insets
        }

        metadataDelegate?.registerHandler(for: Self.type, animating: true) { metadata in
            dialogWrapperViewController.bodyView.targetRectangle = metadata["targetRectangle"]
        }

        return dialogWrapperViewController
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

@available(iOS 13.0, *)
extension AppcuesTooltipTrait {
    enum TooltipPosition: String, Decodable {
        case top
        case bottom
        case leading
        case trailing
    }
}
