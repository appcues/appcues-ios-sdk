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

    let nsDuration: UInt64

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.nsDuration = UInt64(config.duration * 1_000_000)
    }

    init(duration: TimeInterval) {
        self.nsDuration = UInt64(duration * 1_000_000_000)
    }

    func execute() async throws {
        try await Task.sleep(nanoseconds: nsDuration)
    }
}
