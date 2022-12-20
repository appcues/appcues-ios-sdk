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
        let style: ExperienceComponent.Style?
    }

    static let type = "@appcues/tooltip"

    weak var metadataDelegate: TraitMetadataDelegate?

    let tooltipStyle: ExperienceComponent.Style?

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else { return nil }
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
        let dialogWrapperViewController = ExperienceWrapperViewController<TooltipWrapperView>(wrapping: containerController)
        dialogWrapperViewController.configureStyle(tooltipStyle)

        metadataDelegate?.registerHandler(for: Self.type, animating: false) { metadata in
            // layout everything before adjusting the position so that only the position animates when another layout pass runs
            dialogWrapperViewController.bodyView.layoutIfNeeded()
            dialogWrapperViewController.bodyView.targetRectangle = metadata["targetRectangle"]
        }
        metadataDelegate?.registerHandler(for: Self.type, animating: true) { _ in
            dialogWrapperViewController.bodyView.layoutIfNeeded()
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
