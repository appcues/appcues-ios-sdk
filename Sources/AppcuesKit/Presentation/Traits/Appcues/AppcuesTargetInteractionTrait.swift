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
    private let renderContext: RenderContext

    private let tapActions: [Experience.Action]
    private let longPressActions: [Experience.Action]

    private lazy var targetView: UIView = {
        let view = HitTestingOverrideUIView(overrideApproach: .applyMask)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTarget)))
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPressTarget)))
        return view
    }()

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues
        self.renderContext = configuration.renderContext

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
        guard var newTarget: CGRect = metadata["targetRectangle"], metadata[isSet: "backdropBackgroundColor"] else {
            targetView.removeFromSuperview()
            return
        }

        if targetView.superview != backdropView {
            targetView.removeFromSuperview()
            backdropView.addSubview(targetView)
            targetView.pin(to: backdropView)
        }

        // apply any additional spread to the target that may be specified by a keyhole
        newTarget = newTarget.spread(by: metadata["keyholeSpread"])

        // If we have a keyhole defined on the target, prefer to use this for the tap target
        // as it may be larger or a different shape (circle). We use a HitTestingOverrideUIView
        // for this target, so setting the mask to match the keyhole will cause it to
        // only capture taps inside of that mask area. If no keyhole set, it will default
        // to the target rectangle space only.
        targetView.layer.mask = getKeyholeShapeMask(backdropView: backdropView, targetRectangle: newTarget, metadata: metadata)
    }

    @objc
    private func didTapTarget() {
        guard !tapActions.isEmpty, let actionRegistry = appcues?.container.resolve(ActionRegistry.self) else {
            return
        }

        actionRegistry.enqueue(
            actionModels: tapActions,
            level: .step,
            renderContext: renderContext,
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
            renderContext: renderContext,
            interactionType: "Target Long Pressed",
            viewDescription: "Target Rectangle"
        )
    }

    // simplified version of how AppcuesBackdropKeyholeTrait gets the mask layer for a keyhole
    // in this case, we just want a CAShapeLayer for hit testing, and are not concerned with animations
    // or gradients for the circle blur - just the bounds of the keyhole
    private func getKeyholeShapeMask(backdropView: UIView, targetRectangle: CGRect, metadata: AppcuesTraitMetadata) -> CALayer? {
        guard backdropView.bounds != .zero else { return nil }

        // if no keyhole, just use a rectangle that matches the target exactly, no corner radius
        let keyholeShape: AppcuesBackdropKeyholeTrait.KeyholeShape = metadata["keyholeShape"] ?? .rectangle(cornerRadius: 0)
        let keyholeBezierPath = keyholeShape.path(for: targetRectangle, includeBlur: true)

        let shapeMaskLayer = CAShapeLayer()
        shapeMaskLayer.path = keyholeBezierPath.cgPath
        return shapeMaskLayer
    }
}
