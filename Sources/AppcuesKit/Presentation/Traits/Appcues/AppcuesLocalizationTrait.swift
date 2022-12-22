//
//  File.swift
//  
//
//  Created by James Ellis on 12/22/22.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesLocalizationTrait: ExperienceTrait {
    struct Config: Decodable {
        let translate: Bool?
        let source: String
        let target: String?
    }

    static var type: String = "@appcues/localization"

    weak var metadataDelegate: TraitMetadataDelegate?

    let translate: Bool
    let source: String
    let target: String?

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else {
            return nil
        }

        self.translate = config.translate ?? true
        self.source = config.source
        self.target = config.target
    }
}
