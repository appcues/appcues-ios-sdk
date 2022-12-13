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
    static var type: String = "@appcues/backdrop"

    weak var metadataDelegate: TraitMetadataDelegate?

    let backgroundColor: UIColor

    required init?(config: DecodingExperienceConfig, level: ExperienceTraitLevel) {
        if let backgroundColor = UIColor(dynamicColor: config["backgroundColor"]) {
            self.backgroundColor = backgroundColor
        } else {
            return nil
        }
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
