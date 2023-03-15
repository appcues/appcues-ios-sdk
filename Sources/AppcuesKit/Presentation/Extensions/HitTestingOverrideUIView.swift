//
//  HitTestingOverrideUIView.swift
//  AppcuesKit
//
//  Created by Matt on 2023-03-15.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal class HitTestingOverrideUIView: UIView {
    enum OverrideApproach {
        /// Only account for hits that are within the mask path applied to the view.
        case applyMask
        /// Only account for hits that are in subviews of the view, not the view itself.
        case ignoreSelf
    }

    let overrideApproach: OverrideApproach?

    init(overrideApproach: OverrideApproach? = nil) {
        self.overrideApproach = overrideApproach
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        switch overrideApproach {
        case .applyMask:
            return maskHitTest(point, with: event)
        case .ignoreSelf:
            let hitView = super.hitTest(point, with: event)
            return hitView !== self ? hitView : nil
        case .none:
            return super.hitTest(point, with: event)
        }
    }

    private func maskHitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let maskPath = (layer.mask as? CAShapeLayer)?.path else { return super.hitTest(point, with: event) }

        if maskPath.contains(point) {
            return super.hitTest(point, with: event)
        } else {
            // Ignore hits outside of the masked area
            return nil
        }
    }
}
