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
        // swiftlint:disable identifier_name
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
    static let type: String = "@appcues/target-rectangle"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let rect: CGRect

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.rect = CGRect(x: config.x, y: config.y, width: config.width, height: config.height)
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
