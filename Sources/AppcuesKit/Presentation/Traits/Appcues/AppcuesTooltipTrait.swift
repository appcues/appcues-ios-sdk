//
//  AppcuesTooltipTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTooltipTrait: WrapperCreatingTrait, PresentingTrait {
    static let type: String = "@appcues/tooltip"

    let selector: ElementSelector
    var tooltipStyle: ExperienceComponent.Style?

    // swiftlint:disable:next weak_delegate
    let presentationDelegate = PopoverPresentationDelegate()

    required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
        if let selector = ElementSelector(config?["selector"] as? String) {
            self.selector = selector
        } else {
            return nil
        }

        self.tooltipStyle = config?["style", decodedAs: ExperienceComponent.Style.self]
    }

    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
        guard let sourceView = UIApplication.shared.windows.first(where: { !($0 is DebugUIWindow) })?.viewMatchingSelector(selector) else {
            throw TraitError(description: "tooltip target element not found")
        }

        containerController.modalPresentationStyle = .popover
        containerController.popoverPresentationController?.delegate = presentationDelegate
        containerController.popoverPresentationController?.sourceView = sourceView
        containerController.popoverPresentationController?.passthroughViews = [sourceView]

        if let backgroundColor = UIColor(dynamicColor: tooltipStyle?.backgroundColor) {
            containerController.popoverPresentationController?.backgroundColor = backgroundColor
        }

        return containerController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        // nothing!
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
    class PopoverPresentationDelegate: NSObject, UIPopoverPresentationControllerDelegate {
        func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
            .popover
        }

        func adaptivePresentationStyle(
            for controller: UIPresentationController, traitCollection: UITraitCollection
        ) -> UIModalPresentationStyle {
            .none
        }
    }
}
