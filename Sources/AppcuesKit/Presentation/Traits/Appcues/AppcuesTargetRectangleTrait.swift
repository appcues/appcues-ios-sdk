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
    static let type: String = "@appcues/target-rectangle"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let rect: CGRect

    required init?(config: DecodingExperienceConfig, level: ExperienceTraitLevel) {
        // swiftlint:disable identifier_name
        if let x: CGFloat = config["x"],
           let y: CGFloat = config["y"],
           let width: CGFloat = config["width"],
           let height: CGFloat = config["height"] {
            self.rect = CGRect(x: x, y: y, width: width, height: height)
        } else {
            return nil
        }
    }

    func decorate(backdropView: UIView) throws {
        // NOTE: if this trait evolves to use percentage-based targeting, we'll need to use
        // the frame of the backdropView to determine the specific rectangle coordinates
        metadataDelegate?.set([ "targetRectangle": rect ])
    }

    func undecorate(backdropView: UIView) throws {
        metadataDelegate?.unset(keys: [ "targetRectangle" ])
    }
}
