//
//  AppcuesFrameView.swift
//  AppcuesKit
//
//  Created by James Ellis on 8/18/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// A UIKit view that displays an Appcues experience.
public class AppcuesFrameView: UIView, StateMachineOwning {

    enum Transition: String, Decodable {
        case none
        case fade
    }

    // Managed by the StateMachineDirectory
    internal var renderContext: RenderContext?

    private var _stateMachine: Any?
    @available(iOS 13.0, *)
    internal var stateMachine: ExperienceStateMachine? {
        get { _stateMachine as? ExperienceStateMachine }
        set { _stateMachine = newValue }
    }

    private weak var parentViewController: UIViewController?
    private weak var experienceViewController: UIViewController?

    // when the view content is empty, we use this zero height constraint
    private lazy var emptyHeightConstraint: NSLayoutConstraint = {
        var constraint = heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = false
        return constraint
    }()

    // when the view content is empty, we use this zero width constraint
    private lazy var emptyWidthConstraint: NSLayoutConstraint = {
        var constraint = widthAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = false
        return constraint
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isHidden = true
        configureConstraints(isEmpty: true)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        configureConstraints(isEmpty: true)
    }

    private func configureConstraints(isEmpty: Bool) {
        emptyHeightConstraint.isActive = isEmpty
        emptyWidthConstraint.isActive = isEmpty
    }

    // this will only get called on iOS 13+ from the Appcues class during registration
    internal func configure(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    internal func embed(
        _ experienceController: UIViewController,
        margins: NSDirectionalEdgeInsets,
        transition: Transition,
        completion: (() -> Void)?
    ) {
        guard let viewController = parentViewController else { return }

        configureConstraints(isEmpty: false)

        viewController.embedChildViewController(experienceController, inSuperview: self, margins: margins)
        experienceViewController = experienceController

        switch transition {
        case .none:
            isHidden = false
            completion?()
        case .fade:
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.isHidden = false
                },
                completion: { _ in
                    completion?()
                }
            )
        }
    }

    internal func unembed(_ experienceController: UIViewController, transition: Transition, completion: (() -> Void)?) {
        switch transition {
        case .none:
            isHidden = true
            parentViewController?.unembedChildViewController(experienceController)
            configureConstraints(isEmpty: true)
            completion?()
        case .fade:
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    // possibly have a delegate for these embeds that would allow the host app to have more control over this?
                    self.isHidden = true
                },
                completion: { _ in
                    self.parentViewController?.unembedChildViewController(experienceController)
                    self.configureConstraints(isEmpty: true)
                    completion?()
                }
            )
        }
    }

    /// Set the Frame back to an unregistered state.
    internal func reset() {
        if #available(iOS 13.0, *) {
            stateMachine?.removeAnalyticsObserver()
            try? stateMachine?.transition(.endExperience(markComplete: false))
        }
    }
}
