//
//  AppcuesBackdropTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class AppcuesBackdropTrait: AppcuesBackdropDecoratingTrait {
    struct Config: Decodable {
        let backgroundColor: ExperienceComponent.Style.DynamicColor
    }

    static var type: String = "@appcues/backdrop"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let backgroundColor: UIColor
    private var backdropBackgroundView: UIView?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self),
              let backgroundColor = UIColor(dynamicColor: config.backgroundColor) else {
            return nil
        }
        self.backgroundColor = backgroundColor
    }

    func decorate(backdropView: UIView) throws {
        guard let metadataDelegate = metadataDelegate else {
            handleAdd(backdropColor: backgroundColor, to: backdropView)
            return
        }

        metadataDelegate.set(["backdropBackgroundColor": backgroundColor])

        metadataDelegate.registerHandler(for: Self.type, animating: true) { [weak self] metadata in
            self?.handleAdd(backdropColor: metadata["backdropBackgroundColor"], to: backdropView)
        }
    }

    func undecorate(backdropView: UIView) throws {
        guard let metadataDelegate = metadataDelegate else {
            backdropBackgroundView?.removeFromSuperview()
            backdropBackgroundView = nil
            return
        }

        metadataDelegate.unset(keys: [ "backdropBackgroundColor" ])
    }

    private func handleAdd(backdropColor: UIColor?, to backdropView: UIView) {
        if let backdropBackgroundView = self.backdropBackgroundView {
            backdropBackgroundView.backgroundColor = backdropColor
        } else {
            let backdropBackgroundView = UIView()
            backdropBackgroundView.backgroundColor = backdropColor
            backdropView.insertSubview(backdropBackgroundView, at: 0)
            backdropBackgroundView.pin(to: backdropView)
            self.backdropBackgroundView = backdropBackgroundView
        }
    }
}
