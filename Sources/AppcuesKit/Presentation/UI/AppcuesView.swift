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
    internal private(set) var embedId: String?
    private weak var viewController: UIViewController?

    // the trait that is controlling this AppcuesView
    private var _embedTrait: Any?
    @available(iOS 13.0, *)
    internal var embedTrait: AppcuesEmbedTrait? {
        get {
            _embedTrait as? AppcuesEmbedTrait
        }
        set {
            _embedTrait = newValue
        }
    }

    internal weak var experienceController: UIViewController?

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
    internal func configure(appcues: Appcues, embedId: String, viewController: UIViewController) {
        self.appcues = appcues
        self.embedId = embedId
        self.viewController = viewController
        trackEmbed()
    }
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        isAttachedToView = true
        trackEmbed()
    }

    internal func embed(_ experienceController: UIViewController, margins: NSDirectionalEdgeInsets, animated: Bool) {
        guard let viewController = viewController else { return }

        configureConstraints(isEmpty: false)

        self.experienceController = experienceController
        viewController.embedChildViewController(experienceController, inSuperview: self, margins: margins)

        if animated {
            UIView.animate(withDuration: 0.3) {
                // possibly have a delegate for these embeds that would allow the host app to have more control over this?
                self.isHidden = false
            }
        } else {
            isHidden = false
        }
    }

    internal func unembed(animated: Bool) {
        guard let experienceController = experienceController else { return }

        if animated {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    // possibly have a delegate for these embeds that would allow the host app to have more control over this?
                    self.isHidden = true
                },
                completion: { _ in
                    self.viewController?.unembedChildViewController(experienceController)
                    self.experienceController = nil
                    self.configureConstraints(isEmpty: true)
                })
        } else {
            isHidden = true
            viewController?.unembedChildViewController(experienceController)
            self.experienceController = nil
            configureConstraints(isEmpty: true)
        }
    }

    @available(iOS 13.0, *)
    internal func remove() {
        guard let viewController = viewController else { return }
        embedTrait?.remove(viewController: viewController, completion: nil)
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
              let embedId = embedId,
              !embedId.isEmpty,
              let appcues = appcues else { return }

        // this screen call notifies the server that the embed is available for rendering content
        // re-purposing screen for this in the short term, a deeper topic for how to best handle for embeds
        appcues.screen(title: embedId)
    }
}
