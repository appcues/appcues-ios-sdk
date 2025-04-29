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
            if #available(iOS 13.0, *) {
                return stateMachine?.clientControllerPresentationDelegate
            } else {
                return nil
            }
        }
        set {
            if #available(iOS 13.0, *) {
                stateMachine?.clientControllerPresentationDelegate = newValue
            } else {
                // no-op
            }
        }
    }

    // Managed by the StateMachineDirectory
    internal var renderContext: RenderContext?

    /// When retainContent is `true` (default), the embed frame content is cached and re-rendered through any
    /// re-register of this frame until the next `screen_view` qualification occurs. This default behavior enables
    /// common cell-reuse type of use cases, such as embeds in a `UITableView` or `UICollectionView`.
    /// Set this value `false` to require each new register of the same frame ID to qualify for new content
    /// independently of any previous usage of the frame view.
    public var retainContent = true

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

    /// Creates a frame view with the specified frame rectangle.
    /// - Parameters:
    ///   - frame: The frame rectangle for the view.
    ///   - retainContent: Whether content shown in this frame should be retained across multiple re-registers.
    public convenience init(frame: CGRect = .zero, retainContent: Bool = true) {
        self.init(frame: frame)
        self.retainContent = retainContent
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

        self.directionalLayoutMargins = margins
        viewController.embedChildViewController(experienceController, inSuperview: self, respectLayoutMargins: true)
        experienceViewController = experienceController

        switch transition {
        case .none:
            isHidden = false
            completion?()
        case .fade:
            self.isHidden = false
            self.alpha = 0
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.alpha = 1
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
            // Complete async so that experienceController.viewDidDisappear gets called before the state machine moves to .idling
            DispatchQueue.main.async { completion?() }
        case .fade:
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.alpha = 0
                },
                completion: { _ in
                    self.isHidden = true
                    self.parentViewController?.unembedChildViewController(experienceController)
                    self.configureConstraints(isEmpty: true)
                    // Complete async so that experienceController.viewDidDisappear gets called before the state machine moves to .idling
                    DispatchQueue.main.async { completion?() }
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
