//
//  AppcuesTargetRectangleTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTargetRectangleTrait: BackdropDecoratingTrait {
    struct Config: Decodable {
        let contentPreferredPosition: ContentPosition?
        let contentDistanceFromTarget: Double?

        let x: Double?
        let y: Double?
        let width: Double?
        let height: Double?

        let relativeX: Double?
        let relativeY: Double?
        let relativeWidth: Double?
        let relativeHeight: Double?
    }

    static let type: String = "@appcues/target-rectangle"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let config: Config

    private lazy var frameObserverView = FrameObserverView()

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.config = config
    }

    func decorate(backdropView: UIView) throws {
        // The first decorate call on the first step in a group will have a nil window because the views aren't added yet,
        // so skip setting a targetRectangle until we have proper bounds. The change handler below will take care of that.
        if backdropView.window != nil {
            metadataDelegate?.set([
                "contentPreferredPosition": config.contentPreferredPosition,
                "contentDistanceFromTarget": CGFloat(config.contentDistanceFromTarget ?? 0),
                "targetRectangle": calculateRect(bounds: backdropView.bounds)
            ])
        }

        // Monitor the backdrop bounds to recalculate relative positioning on changes.
        backdropView.insertSubview(frameObserverView, at: 0)
        frameObserverView.pin(to: backdropView)
        // Ensure the view bounds are updated *before* we add the frame observer block.
        frameObserverView.layoutIfNeeded()

        frameObserverView.onChange = { [weak self] bounds in
            self?.metadataDelegate?.set([
                "contentPreferredPosition": self?.config.contentPreferredPosition,
                "contentDistanceFromTarget": CGFloat(self?.config.contentDistanceFromTarget ?? 0),
                "targetRectangle": self?.calculateRect(bounds: bounds)
            ])
            // Force an update so that traits depending on this value will update.
            self?.metadataDelegate?.publish()
        }
    }

    func undecorate(backdropView: UIView) throws {
        metadataDelegate?.unset(keys: [ "contentPreferredPosition", "contentDistanceFromTarget", "targetRectangle" ])

        frameObserverView.removeFromSuperview()
        frameObserverView.onChange = nil
    }

    private func calculateRect(bounds: CGRect) -> CGRect {
        CGRect(
            x: bounds.width * (config.relativeX ?? 0) + (config.x ?? 0),
            y: bounds.height * (config.relativeY ?? 0) + (config.y ?? 0),
            width: bounds.width * (config.relativeWidth ?? 0) + (config.width ?? 0),
            height: bounds.height * (config.relativeHeight ?? 0) + (config.height ?? 0)
        )
    }
}

private class FrameObserverView: UIView {
    private var oldBounds: CGRect = .zero
    var onChange: ((_ bounds: CGRect) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        if oldBounds != bounds {
            onChange?(bounds)
        }
        oldBounds = bounds
    }
}
