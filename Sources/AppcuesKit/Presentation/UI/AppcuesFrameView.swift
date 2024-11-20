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

    /// The delegate object that manages and observes presentations in this embed frame.
    public weak var presentationDelegate: AppcuesPresentationDelegate? {
        get {
            stateMachine?.clientControllerPresentationDelegate
        }
        set {
            stateMachine?.clientControllerPresentationDelegate = newValue
        }
    }

    // Managed by the StateMachineDirectory
    internal var renderContext: RenderContext?

    internal var stateMachine: ExperienceStateMachine?

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
        transition: Transition
    ) async {
        guard let viewController = parentViewController else { return }

        configureConstraints(isEmpty: false)

        self.directionalLayoutMargins = margins
        viewController.embedChildViewController(experienceController, inSuperview: self, respectLayoutMargins: true)
        experienceViewController = experienceController

        switch transition {
        case .none:
            isHidden = false
        case .fade:
            self.isHidden = false
            self.alpha = 0
            await withCheckedContinuation { continuation in
                UIView.animate(
                    withDuration: 0.3,
                    animations: {
                        self.alpha = 1
                    },
                    completion: { _ in
                        continuation.resume()
                    }
                )
            }
        }
    }

    internal func unembed(_ experienceController: UIViewController, transition: Transition) async {
        switch transition {
        case .none:
            isHidden = true
            parentViewController?.unembedChildViewController(experienceController)
            configureConstraints(isEmpty: true)
        case .fade:
            await withCheckedContinuation { continuation in
                UIView.animate(
                    withDuration: 0.3,
                    animations: {
                        self.alpha = 0
                    },
                    completion: { _ in
                        self.isHidden = true
                        self.parentViewController?.unembedChildViewController(experienceController)
                        self.configureConstraints(isEmpty: true)
                        continuation.resume()
                    }
                )
            }
        }
    }

    /// Set the Frame back to an unregistered state.
    internal func reset() async {
        stateMachine?.removeAnalyticsObserver()
        try? await stateMachine?.transition(.endExperience(markComplete: false))
    }
}
