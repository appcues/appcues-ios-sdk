//
//  AppcuesDelayAction.swift
//  AppcuesKit
//
//  Created by Matt on 2024-06-05.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation

internal class AppcuesDelayAction: AppcuesExperienceAction {
    struct Config: Decodable {
        let duration: Int
    }

    static let type = "@appcues/delay"

    let duration: TimeInterval

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.duration = Double(config.duration) / 1_000
    }

    init(duration: TimeInterval) {
        self.duration = duration
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { completion() }
    }
}
