//
//  AppcuesView.swift
//  AppcuesKit
//
//  Created by James Ellis on 8/18/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
public class AppcuesView: UIView {

    private var isConfigured = false        // appcues instance, embed ID, and view controller set
    private var isAttachedToView = false    // didMoveToSuperView has been called
    private var hasTracked = false          // has tracked the embed to check for qualified content

    private var appcues: Appcues?
    internal private(set) var embedId: String?
    private weak var viewController: UIViewController?

    // the trait that is controlling this AppcuesView
    internal var embedTrait: AppcuesEmbedTrait?

    internal weak var experienceController: UIViewController?

    private var heightObserver: NSKeyValueObservation?

    private lazy var preferredHeightConstraint: NSLayoutConstraint = {
        var constraint = heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = true
        return constraint
    }()

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }

    internal func configure(appcues: Appcues, embedId: String, viewController: UIViewController) {
        self.appcues = appcues
        self.embedId = embedId
        self.viewController = viewController

        isConfigured = true

        trackEmbed()
    }

    private func trackEmbed() {
        // only track if we have not already, the required props have been configured, and we have a valid embed ID
        guard !hasTracked, isConfigured, isAttachedToView, let embedId = embedId, !embedId.isEmpty, let appcues = appcues else { return }
        // this screen call notifies the server that the embed is available for rendering content
        // re-purposing screen for this in the short term, a deeper topic for how to best handle for embeds
        appcues.screen(title: embedId)
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()

        if subviews.isEmpty {
            // possibly have a delegate for these embeds that would allow the host app to have more control over this?
            isHidden = true
        }

        isAttachedToView = true

        trackEmbed()
    }

    internal func embed(_ experienceController: UIViewController, margins: NSDirectionalEdgeInsets, animated: Bool) {
        guard let viewController = viewController else { return }

        heightObserver = experienceController.observe(\.preferredContentSize) { _, _ in
            self.preferredHeightConstraint.constant = experienceController.preferredContentSize.height
        }

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

        preferredHeightConstraint.constant = 0
        // preferredContentSize = .zero
        heightObserver = nil

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
                })
        } else {
            isHidden = true
            viewController?.unembedChildViewController(experienceController)
            self.experienceController = nil
        }
    }

    internal func remove() {
        guard let viewController = viewController else { return }
        embedTrait?.remove(viewController: viewController, completion: nil)
    }

}
