//
//  AppcuesUpdateProfileAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesUpdateProfileAction: ExperienceAction {
    static let type = "@appcues/update-profile"

    let properties: [String: Any]

    required init?(config: DecodingExperienceConfig) {
        let properties = config.safeValues
        if !properties.isEmpty {
            self.properties = properties
        } else {
            return nil
        }
    }

    func execute(inContext appcues: Appcues, completion: ActionRegistry.Completion) {
        let userID = appcues.container.resolve(DataStoring.self).userID
        appcues.identify(userID: userID, properties: properties)
        completion()
    }
}
