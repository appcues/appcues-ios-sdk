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

    let eventName: String

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.eventName = config.eventName
    }

    func execute(inContext appcues: Appcues, completion: ActionRegistry.Completion) {
        appcues.track(name: eventName)
        completion()
    }
}
