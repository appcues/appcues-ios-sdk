//
//  AppcuesTrackAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesTrackAction: AppcuesExperienceAction {
    struct Config: Decodable {
        let eventName: String
    }

    static let type = "@appcues/track"

    private weak var appcues: Appcues?

    let eventName: String

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.eventName = config.eventName
    }

    func execute(completion: ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        appcues.track(name: eventName)
        completion()
    }
}
