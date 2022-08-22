//
//  AppcuesStickyContentTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal class AppcuesStickyContentTrait: StepDecoratingTrait {
    static let type = "@appcues/sticky-content"

    let edge: Edge
    let content: ExperienceComponent

    required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
        if let edge = Edge(config?["edge"] as? String), let content = config?["content", decodedAs: ExperienceComponent.self] {
            self.edge = edge
            self.content = content
        } else {
            return nil
        }
    }

    func decorate(stepController viewController: UIViewController) throws {
        // Need to cast for access to the viewModel.
        guard let viewController = viewController as? ExperienceStepViewController else { return }

        // Must have the environmentObject so any actions in the sticky content can be applied.
        let stickyContentVC = StickyHostingController(rootView: content.view.environmentObject(viewController.viewModel))

        // Add the stick content to the parent controller.
        viewController.addChild(stickyContentVC)
        viewController.view.addSubview(stickyContentVC.view)
        stickyContentVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints(for: edge, container: viewController.view, child: stickyContentVC.view))
        stickyContentVC.didMove(toParent: viewController)

        // Pass sticky content size changes to the parent controller to update the insets.
        stickyContentVC.onContentSizeChange = { [weak self, weak viewController] size in
            guard let self = self, let viewController = viewController else { return }
            switch self.edge {
            case .top:
                viewController.additionalSafeAreaInsets.top = size.height
            case .leading:
                // TODO: mapping left->leading could be backwards for RTL
                viewController.additionalSafeAreaInsets.left = size.width
            case .bottom:
                viewController.additionalSafeAreaInsets.bottom = size.height
            case .trailing:
                viewController.additionalSafeAreaInsets.right = size.width
            }
        }
    }

    // Determine the constraints for the sticky view by the `Edge` it's attached to.
    private func constraints(for: Edge, container containerView: UIView, child stickyView: UIView) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        switch edge {
        case .top, .bottom:
            constraints.append(contentsOf: [
                stickyView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                stickyView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        case .leading, .trailing:
            constraints.append(contentsOf: [
                stickyView.topAnchor.constraint(equalTo: containerView.topAnchor),
                stickyView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        switch edge {
        case .top:
            constraints.append(stickyView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor))
        case .leading:
            constraints.append(stickyView.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor))
        case .bottom:
            constraints.append(stickyView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor))
        case .trailing:
            constraints.append(stickyView.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor))
        }

        return constraints
    }
}

@available(iOS 13.0, *)
extension AppcuesStickyContentTrait {
    /// HostingController that reports `frame` size changes.
    class StickyHostingController<Content: View>: AppcuesHostingController<Content> {

        var onContentSizeChange: ((CGSize) -> Void)?

        private var previousContentSize: CGSize = .zero

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            // the content size is the frame size of the view minus any safe area insets
            let contentSize = CGSize(
                width: view.frame.width - view.safeAreaInsets.left - view.safeAreaInsets.right,
                height: view.frame.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)

            if contentSize != previousContentSize {
                onContentSizeChange?(contentSize)
                previousContentSize = contentSize
            }
        }
    }
}
