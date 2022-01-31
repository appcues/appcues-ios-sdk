//
//  AppcuesStickyContentTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesStickyContentTrait: StepDecoratingTrait {
    static let type = "@appcues/sticky-content"

    let groupID: String?
    let edge: Edge
    let content: ExperienceComponent

    init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String
        if let edge = Edge(config?["edge"] as? String), let content = config?["content", decodedAs: ExperienceComponent.self] {
            self.edge = edge
            self.content = content
        } else {
            return nil
        }
    }

    func decorate(stepController viewController: UIViewController) {
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
        stickyContentVC.onSizeChange = { size, safeArea in
            switch edge {
            case .top:
                viewController.additionalSafeAreaInsets.top = size.height - safeArea.top
            case .leading:
                // TODO: mapping left->leading could be backwards for RTL
                viewController.additionalSafeAreaInsets.left = size.width - safeArea.left
            case .bottom:
                viewController.additionalSafeAreaInsets.bottom = size.height - safeArea.bottom
            case .trailing:
                viewController.additionalSafeAreaInsets.right = size.width - safeArea.right
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

extension AppcuesStickyContentTrait {
    /// HostingController that reports `frame` size changes.
    class StickyHostingController<Content: View>: AppcuesHostingController<Content> {

        var onSizeChange: ((CGSize, UIEdgeInsets) -> Void)?

        private var previousSize: CGSize = .zero

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            if view.frame.size != previousSize {
                onSizeChange?(view.frame.size, view.safeAreaInsets)
                previousSize = view.frame.size
            }
        }
    }
}
