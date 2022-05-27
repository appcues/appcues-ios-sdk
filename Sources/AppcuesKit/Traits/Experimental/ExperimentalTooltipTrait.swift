//
//  ExperimentalTooltipTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalTooltipTrait: WrapperCreatingTrait {
    static let type: String = "@experimental/tooltip"

    let accessibilityIdentifier: String
    var tooltipStyle: ExperienceComponent.Style?

    // swiftlint:disable:next weak_delegate
    let presentationDelegate = PopoverPresentationDelegate()

    required init?(config: [String: Any]?) {
        if let accessibilityIdentifier = config?["accessibilityIdentifier"] as? String {
            self.accessibilityIdentifier = accessibilityIdentifier
        } else {
            return nil
        }

        self.tooltipStyle = config?["style", decodedAs: ExperienceComponent.Style.self]
    }

    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
        guard let sourceView = UIApplication.shared.activeKeyWindow?.view(matching: accessibilityIdentifier) else {
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
}

@available(iOS 13.0, *)
extension ExperimentalTooltipTrait {
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

extension UIView {
    func view(matching description: String) -> UIView? {
        if accessibilityIdentifier ?? accessibilityLabel == description { return self }

        for subview in subviews {
            if let view = subview.view(matching: description) {
                return view
            }
        }

        return nil
    }
}
