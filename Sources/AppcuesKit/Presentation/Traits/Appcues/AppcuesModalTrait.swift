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

    enum Transition {
        case fade
        case slide(edgeIn: TransitionEdge, edgeOut: TransitionEdge)
    }

    enum TransitionEdge: String {
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
        let slideInEdge: String? // only used if transition is "slide"
        let slideOutEdge: String? // only used if transition is "slide"
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

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        if let dialogController = wrapperController as? ExperienceWrapperViewController {
            dialogController.view.insertSubview(backdropView, at: 0)
            backdropView.pin(to: dialogController.view)
            dialogController.backdropView = backdropView
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

@available(iOS 13.0, *)
extension AppcuesModalTrait.Config {
    func toTransition() -> AppcuesModalTrait.Transition {

        switch self.transition {
        case "slide":
            // will default to any explicitly specified edge from the config, but
            // fall back to the expected default based on the horizontal and vertical
            // position of the modal
            var edgeIn: AppcuesModalTrait.TransitionEdge
            var edgeOut: AppcuesModalTrait.TransitionEdge

            let configEdgeIn = self.slideInEdge.flatMap { AppcuesModalTrait.TransitionEdge(rawValue: $0) }
            let configEdgeOut = self.slideOutEdge.flatMap { AppcuesModalTrait.TransitionEdge(rawValue: $0) }

            let horizontalAlign = style?.horizontalAlignment ?? "center"
            let verticalAlign = style?.verticalAlignment ?? "center"

            switch horizontalAlign {
            case "leading":
                edgeIn = configEdgeIn ?? .leading
                edgeOut = configEdgeOut ?? edgeIn
            case "trailing":
                edgeIn = configEdgeIn ?? .trailing
                edgeOut = configEdgeOut ?? edgeIn
            default:
                switch verticalAlign {
                case "top":
                    edgeIn = configEdgeIn ?? .top
                    edgeOut = configEdgeOut ?? edgeIn
                case "bottom":
                    edgeIn = configEdgeIn ?? .bottom
                    edgeOut = configEdgeOut ?? edgeIn
                default:
                    edgeIn = configEdgeIn ?? .center
                    edgeOut = configEdgeOut ?? edgeIn
                }
            }

            return .slide(edgeIn: edgeIn, edgeOut: edgeOut)

        default:
            return .fade
        }
    }
}
