//
//  AppcuesStickyContentTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesStickyContentTrait: ExperienceTrait {
    static let type = "@appcues/sticky-content"

    let edge: Edge
    let content: ExperienceComponent

    init?(config: [String: Any]?) {
        if let edge = Edge(config?["edge"] as? String), let content = config?["content", decodedAs: ExperienceComponent.self] {
            self.edge = edge
            self.content = content
        } else {
            return nil
        }
    }

    func apply(to experienceController: UIViewController, containedIn wrappingController: UIViewController) -> UIViewController {
        // Need to cast for access to the viewModel and the customScrollInsets property.
        guard let experienceController = experienceController as? ExperiencePagingViewController else { return wrappingController }

        // Must have the environmentObject so any actions in the sticky content can be applied.
        let stickyContentVC = StickyHostingController(rootView: content.view.environmentObject(experienceController.viewModel))

        // Add the stick content to the parent controller.
        experienceController.addChild(stickyContentVC)
        experienceController.view.addSubview(stickyContentVC.view)
        stickyContentVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints(for: edge, container: experienceController.view, child: stickyContentVC.view))
        stickyContentVC.didMove(toParent: experienceController)

        // Pass sticky content size changes to the parent controller to update the insets.
        stickyContentVC.onSizeChange = { size, safeArea in
            switch edge {
            case .top:
                experienceController.additionalSafeAreaInsets.top = size.height - safeArea.top
            case .leading:
                // TODO: mapping left->leading could be backwards for RTL
                experienceController.additionalSafeAreaInsets.left = size.width - safeArea.left
            case .bottom:
                experienceController.additionalSafeAreaInsets.bottom = size.height - safeArea.bottom
            case .trailing:
                experienceController.additionalSafeAreaInsets.right = size.width - safeArea.right
            }
        }

        // Return the unmodified `wrappingController`.
        return wrappingController
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
