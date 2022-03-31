//
//  AppcuesUpdateProfileAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal struct AppcuesUpdateProfileAction: ExperienceAction {
    static let type = "@appcues/update-profile"

    let properties: [String: Any]

    init?(config: [String: Any]?) {
        if let properties = config {
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
