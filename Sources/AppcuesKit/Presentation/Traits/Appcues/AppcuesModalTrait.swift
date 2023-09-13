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

    enum Transition: Equatable {
        case fade
        case slide(edge: TransitionEdge)
    }

    enum TransitionEdge: String, Equatable {
        case leading
        case trailing
        case top
        case bottom
        case center
    }

    struct Config: Decodable {
        let presentationStyle: PresentationStyle
        let style: ExperienceComponent.Style?
        let transition: String?
    }

    static let type = "@appcues/modal"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let presentationStyle: PresentationStyle
    private let modalStyle: ExperienceComponent.Style?
    private let transition: Transition

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.presentationStyle = config.presentationStyle
        self.modalStyle = config.style
        self.transition = config.toTransition()
    }

    func decorate(stepController: UIViewController) throws {
        // Need to cast for access to the padding property.
        guard let stepController = stepController as? ExperienceStepViewController else { return }
        stepController.padding = NSDirectionalEdgeInsets(paddingFrom: modalStyle)
    }

    func createWrapper(around containerController: AppcuesExperienceContainerViewController) throws -> UIViewController {
        containerController.modalPresentationStyle = presentationStyle.modalPresentationStyle

        if presentationStyle == .dialog {
            return ExperienceWrapperViewController(wrapping: containerController)
                .configureStyle(modalStyle, transition: transition)
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

    func getBackdrop(for wrapperController: UIViewController) -> UIView? {
        return (wrapperController as? ExperienceWrapperViewController)?.bodyView.backdropView
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

@available(iOS 13.0, *)
extension AppcuesModalTrait.Config {
    func toTransition() -> AppcuesModalTrait.Transition {

        switch self.transition {
        case "slide":
            // determine the slide edge based on the horizontal and vertical
            // position of the modal
            var edge: AppcuesModalTrait.TransitionEdge

            let horizontalAlign = style?.horizontalAlignment ?? "center"
            let verticalAlign = style?.verticalAlignment ?? "center"

            switch (horizontalAlign, verticalAlign) {
            case ("leading", _):
                edge = .leading
            case ("trailing", _):
                edge = .trailing
            case (_, "top"):
                edge = .top
            case (_, "bottom"):
                edge = .bottom
            default:
                edge = .center
            }

            return .slide(edge: edge)

        default:
            return .fade
        }
    }
}
