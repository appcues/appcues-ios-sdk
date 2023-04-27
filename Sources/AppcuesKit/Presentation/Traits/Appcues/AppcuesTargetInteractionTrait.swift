//
//  AppcuesTargetInteractionTrait.swift
//  AppcuesKit
//
//  Created by James Ellis on 4/25/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTargetInteractionTrait: AppcuesBackdropDecoratingTrait {
    struct Config: Decodable {
        let actions: [Experience.Action]?
    }

    enum ActionType: String {
        case tap
        case longPress
    }

    static let type: String = "@appcues/target-interaction"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private weak var appcues: Appcues?

    private let tapActions: [Experience.Action]
    private let longPressActions: [Experience.Action]

    private lazy var targetView: UIView = {
        let view = UIView()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTarget)))
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPressTarget)))
        return view
    }()

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        let config = configuration.decode(Config.self)
        let actions = config?.actions ?? []

        tapActions = actions.filter { ActionType(rawValue: $0.trigger) == .tap }
        longPressActions = actions.filter { ActionType(rawValue: $0.trigger) == .longPress }
    }

    func decorate(backdropView: UIView) throws {
        guard let metadataDelegate = metadataDelegate else {
            // nothing to do without a targetRectangle from the metadata dictionary
            targetView.removeFromSuperview()
            return
        }

        metadataDelegate.registerHandler(for: Self.type, animating: false) { [weak self] in
            self?.handle(backdropView: backdropView, metadata: $0)
        }
    }

    func undecorate(backdropView: UIView) throws {
        targetView.removeFromSuperview()

        metadataDelegate?.removeHandler(for: Self.type)
    }

    private func handle(backdropView: UIView, metadata: AppcuesTraitMetadata) {
        guard let newTarget: CGRect = metadata["targetRectangle"] else {
            targetView.frame = .zero
            targetView.removeFromSuperview()
            return
        }

        if targetView.superview != backdropView {
            targetView.removeFromSuperview()
            backdropView.addSubview(targetView)
        }

        targetView.frame = newTarget
    }

    @objc
    private func didTapTarget() {
        guard !tapActions.isEmpty, let actionRegistry = appcues?.container.resolve(ActionRegistry.self) else {
            return
        }

        actionRegistry.enqueue(
            actionModels: tapActions,
            level: .step,
            interactionType: "Target Tapped",
            viewDescription: "Target Rectangle"
        )
    }

    @objc
    private func didLongPressTarget() {
        guard !longPressActions.isEmpty, let actionRegistry = appcues?.container.resolve(ActionRegistry.self) else {
            return
        }

        actionRegistry.enqueue(
            actionModels: longPressActions,
            level: .step,
            interactionType: "Target Long Pressed",
            viewDescription: "Target Rectangle"
        )
    }
}
