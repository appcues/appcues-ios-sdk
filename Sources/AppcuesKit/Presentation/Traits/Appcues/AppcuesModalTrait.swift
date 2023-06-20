//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesModalTrait: AppcuesStepDecoratingTrait, AppcuesWrapperCreatingTrait, AppcuesPresentingTrait {
    struct Config: Decodable {
        let presentationStyle: PresentationStyle
        let style: ExperienceComponent.Style?
    }

    static let type = "@appcues/modal"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let presentationStyle: PresentationStyle
    private let modalStyle: ExperienceComponent.Style?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.presentationStyle = config.presentationStyle
        self.modalStyle = config.style
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(paddingFrom: modalStyle)
    }

    func createWrapper(around containerController: AppcuesExperienceContainerViewController) throws -> UIViewController {
        containerController.modalPresentationStyle = presentationStyle.modalPresentationStyle

        if presentationStyle == .dialog {
            return ExperienceWrapperViewController(wrapping: containerController).configureStyle(modalStyle)
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
        if let dialogController = wrapperController as? ExperienceWrapperViewController {
            dialogController.view.insertSubview(backdropView, at: 0)
            backdropView.pin(to: dialogController.view)
        }
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

@available(iOS 13.0, *)
extension AppcuesModalTrait {
    enum PresentationStyle: String, Decodable {
        case full
        case dialog
        case sheet
        case halfSheet

        var modalPresentationStyle: UIModalPresentationStyle {
            switch self {
            case .full:
                return UIDevice.current.userInterfaceIdiom == .pad ? .pageSheet : .overFullScreen
            case .dialog:
                return .overFullScreen
            case .sheet:
                return .formSheet
            case .halfSheet:
                return .formSheet
            }
        }
    }
}
