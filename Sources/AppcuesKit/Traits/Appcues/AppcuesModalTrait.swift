//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalTrait: ContainerCreatingTrait, WrapperCreatingTrait, PresentingTrait {
    static let type = "@appcues/modal"

    let groupID: String?
    let presentationStyle: PresentationStyle
    let backdropColor: UIColor?
    let modalStyle: ExperienceComponent.Style?

    init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String

        if let presentationStyle = PresentationStyle(rawValue: config?["presentationStyle"] as? String ?? "") {
            self.presentationStyle = presentationStyle
        } else {
            return nil
        }

        self.backdropColor = UIColor(dynamicColor: config?["backdropColor", decodedAs: ExperienceComponent.Style.DynamicColor.self])
        self.modalStyle = config?["style", decodedAs: ExperienceComponent.Style.self]
    }

    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceStepContainer {
        // TODO: disable swipe-to-page by default. @appcues/carousel should enable it.
        ExperiencePagingViewController(stepControllers: stepControllers)
    }

    func createWrapper(around containerController: ExperienceStepContainer) -> UIViewController {
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

    func present(viewController: UIViewController) throws {
        UIApplication.shared.topViewController()?.present(viewController, animated: true)
    }

    func remove(viewController: UIViewController) {
        viewController.dismiss(animated: true)
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
