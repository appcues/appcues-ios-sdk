//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesModalTrait: StepDecoratingTrait, WrapperCreatingTrait, PresentingTrait {
    static let type = "@appcues/modal"

    let presentationStyle: PresentationStyle
    let modalStyle: ExperienceComponent.Style?

    required init?(config: [String: Any]?) {
        if let presentationStyle = PresentationStyle(rawValue: config?["presentationStyle"] as? String ?? "") {
            self.presentationStyle = presentationStyle
        } else {
            return nil
        }

        self.modalStyle = config?["style", decodedAs: ExperienceComponent.Style.self]
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(
            top: modalStyle?.paddingTop ?? 0,
            leading: modalStyle?.paddingLeading ?? 0,
            bottom: modalStyle?.paddingBottom ?? 0,
            trailing: modalStyle?.paddingTrailing ?? 0)
    }

    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
        containerController.modalPresentationStyle = presentationStyle.modalPresentationStyle

        if presentationStyle == .dialog {
            return DialogContainerViewController(wrapping: containerController).configureStyle(modalStyle)
        }

        if let backgroundColor = UIColor(dynamicColor: modalStyle?.backgroundColor) {
            containerController.view.backgroundColor = backgroundColor
        }

        if #available(iOS 15.0, *), let sheet = containerController.sheetPresentationController {
            sheet.preferredCornerRadius = CGFloat(modalStyle?.cornerRadius)

            if presentationStyle == .halfSheet {
                sheet.detents = [.medium()]
            }
        }

        return containerController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        if let dialogController = wrapperController as? DialogContainerViewController {
            dialogController.view.insertSubview(backdropView, at: 0)
            backdropView.pin(to: dialogController.view)
        }
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
extension AppcuesModalTrait {
    enum PresentationStyle: String {
        case full
        case dialog
        case sheet
        case halfSheet

        var modalPresentationStyle: UIModalPresentationStyle {
            switch self {
            case .full, .dialog:
                return .overFullScreen
            case .sheet:
                return .formSheet
            case .halfSheet:
                return .pageSheet
            }
        }
    }
}
