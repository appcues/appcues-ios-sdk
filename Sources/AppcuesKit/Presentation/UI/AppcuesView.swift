//
//  AppcuesView.swift
//  AppcuesKit
//
//  Created by James Ellis on 8/18/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

public class AppcuesView: UIView {

    private var isAttachedToView = false    // didMoveToSuperView has been called
    private var hasTracked = false          // has tracked the embed to check for qualified content

    private weak var appcues: Appcues?
    internal private(set) var embedID: String?
    private weak var parentViewController: UIViewController?

    // when the view content is empty, we use this zero height constraint
    private lazy var emptyHeightConstraint: NSLayoutConstraint = {
        var constraint = heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = false
        return constraint
    }()

    // when the view content is non-empty, we use a >= 1 height constraint to allow for dynamic
    // sizing based on the content
    private lazy var nonEmptyHeightConstraint: NSLayoutConstraint = {
        var constraint = heightAnchor.constraint(greaterThanOrEqualToConstant: 1)
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

    // when the view content is non-empty, we use a >= 1 width constraint to allow for dynamic
    // sizing based on the content
    private lazy var nonEmptyWidthConstraint: NSLayoutConstraint = {
        var constraint = widthAnchor.constraint(greaterThanOrEqualToConstant: 1)
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
        nonEmptyHeightConstraint.isActive = !isEmpty
        emptyWidthConstraint.isActive = isEmpty
        nonEmptyWidthConstraint.isActive = !isEmpty
    }

    // this will only get called on iOS 13+ from the Appcues class during registration
    internal func configure(appcues: Appcues, embedID: String, parentViewController: UIViewController) {
        self.appcues = appcues
        self.embedID = embedID
        self.parentViewController = parentViewController
        trackEmbed()
    }
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        isAttachedToView = true
        trackEmbed()
    }

    internal func embed(_ experienceController: UIViewController, margins: NSDirectionalEdgeInsets, animated: Bool, completion: (() -> Void)?) {
        guard let viewController = parentViewController else { return }

        configureConstraints(isEmpty: false)

        viewController.embedChildViewController(experienceController, inSuperview: self, margins: margins)

        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    // possibly have a delegate for these embeds that would allow the host app to have more control over this?
                    self.isHidden = false
                },
                completion: { _ in
                    completion?()
                }
            )
        } else {
            isHidden = false
            completion?()
        }
    }

    internal func unembed(_ experienceController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if animated {
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
        } else {
            isHidden = true
            parentViewController?.unembedChildViewController(experienceController)
            configureConstraints(isEmpty: true)
            completion?()
        }
    }

    private func trackEmbed() {
        // only track if we have not already, the required props have been configured, and we have a valid embed ID
        // also - only support tracking on iOS 13+ since that is the requirement for rendering experience content
        //
        // in practice - it would never get here, since the Appcues registration would be skipped and the appcues
        // instance below will be nil.
        guard #available(iOS 13.0, *),
              !hasTracked,
              isAttachedToView,
              let embedID = embedID,
              !embedID.isEmpty,
              let appcues = appcues else { return }

        // this screen call notifies the server that the embed is available for rendering content
        // re-purposing screen for this in the short term, a deeper topic for how to best handle for embeds
        appcues.screen(title: embedID)
    }
}
