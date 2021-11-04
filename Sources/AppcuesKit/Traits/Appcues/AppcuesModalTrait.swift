//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalTrait: ContainerExperienceTrait {
    static let type = "@appcues/modal"

    var presentationStyle: PresentationStyle
    var cornerRadius: CGFloat?

    init?(config: [String: Any]?) {
        if let presentationStyle = PresentationStyle(rawValue: config?["presentationStyle"] as? String ?? "") {
            self.presentationStyle = presentationStyle
        } else {
            return nil
        }

        if let cornerRadius = config?["cornerRadius"] as? Int {
            self.cornerRadius = CGFloat(cornerRadius)
        }
    }

    func apply(to viewController: UIViewController) -> UIViewController {
        viewController.modalPresentationStyle = presentationStyle.modalPresentationStyle

        if presentationStyle == .dialog {
            let dialogViewController = DialogContainerViewController(dialogViewController: viewController)
            if let cornerRadius = cornerRadius {
                dialogViewController.containerView.dialogView.layer.cornerRadius = cornerRadius
            }
            return dialogViewController
        }

        if #available(iOS 15.0, *), let sheet = viewController.sheetPresentationController {
            sheet.preferredCornerRadius = cornerRadius

            if presentationStyle == .halfSheet {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }

        return viewController
    }
}

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
