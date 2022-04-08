//
//  AppcuesTrackAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesTrackAction: ExperienceAction {
    static let type = "@appcues/track"

    let eventName: String

    required init?(config: [String: Any]?) {
        if let eventName = config?["eventName"] as? String {
            self.eventName = eventName
        } else {
            return nil
        }
    }

    func execute(inContext appcues: Appcues, completion: ActionRegistry.Completion) {
        appcues.track(name: eventName)
        completion()
    }
}
