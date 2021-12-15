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
        guard let experienceController = experienceController as? ExperienceStepViewController else { return wrappingController }

        // Must have the environmentObject so any actions in the sticky content can be applied.
        let stickyContentVC = StickyHostingController(rootView: content.view.environmentObject(experienceController.viewModel))

        // Determine the constraints for the sticky view by the `Edge` it's attached to.
        var constraints: [NSLayoutConstraint] = []
        switch edge {
        case .top, .bottom:
            constraints.append(contentsOf: [
                stickyContentVC.view.leadingAnchor.constraint(equalTo: experienceController.view.leadingAnchor),
                stickyContentVC.view.trailingAnchor.constraint(equalTo: experienceController.view.trailingAnchor)
            ])
        case .leading, .trailing:
            constraints.append(contentsOf: [
                stickyContentVC.view.topAnchor.constraint(equalTo: experienceController.view.topAnchor),
                stickyContentVC.view.bottomAnchor.constraint(equalTo: experienceController.view.bottomAnchor)
            ])
        }
        switch edge {
        case .top:
            constraints.append(stickyContentVC.view.topAnchor.constraint(equalTo: experienceController.view.topAnchor))
        case .leading:
            constraints.append(stickyContentVC.view.leadingAnchor.constraint(equalTo: experienceController.view.leadingAnchor))
        case .bottom:
            constraints.append(stickyContentVC.view.bottomAnchor.constraint(equalTo: experienceController.view.bottomAnchor))
        case .trailing:
            constraints.append(stickyContentVC.view.trailingAnchor.constraint(equalTo: experienceController.view.trailingAnchor))
        }

        // Add the stick content to the parent controller.
        experienceController.addChild(stickyContentVC)
        experienceController.view.insertSubview(stickyContentVC.view, aboveSubview: experienceController.scrollView)
        stickyContentVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints)
        stickyContentVC.didMove(toParent: experienceController)

        // Pass sticky content size changes to the parent controller to update the insets.
        stickyContentVC.onSizeChange = { size, safeArea in
            switch edge {
            case .top:
                experienceController.customScrollInsets.top = size.height - safeArea.top
            case .leading:
                // TODO: mapping left->leading could be backwards for RTL
                experienceController.customScrollInsets.left = size.width - safeArea.left
            case .bottom:
                experienceController.customScrollInsets.bottom = size.height - safeArea.bottom
            case .trailing:
                experienceController.customScrollInsets.right = size.width - safeArea.right
            }
        }

        // Return the unmodified `wrappingController`.
        return wrappingController
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
