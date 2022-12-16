//
//  AppcuesBackdropTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesBackdropTrait: BackdropDecoratingTrait {
    struct Config: Decodable {
        let backgroundColor: ExperienceComponent.Style.DynamicColor?
    }

    static var type: String = "@appcues/backdrop"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let backgroundColor: UIColor

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self),
              let backgroundColor = UIColor(dynamicColor: config.backgroundColor) else {
            return nil
        }
        self.backgroundColor = backgroundColor
    }

    func decorate(backdropView: UIView) throws {
        guard let metadataDelegate = metadataDelegate else {
            backdropView.backgroundColor = backgroundColor
            return
        }

        metadataDelegate.set(["backdropBackgroundColor": backgroundColor])

        metadataDelegate.registerHandler(for: Self.type, animating: true) { metadata in
            backdropView.backgroundColor = metadata["backdropBackgroundColor"]
        }
    }

    func undecorate(backdropView: UIView) throws {
        guard let metadataDelegate = metadataDelegate else {
            backdropView.backgroundColor = nil
            return
        }

        metadataDelegate.unset(keys: [ "backdropBackgroundColor" ])
    }
}
