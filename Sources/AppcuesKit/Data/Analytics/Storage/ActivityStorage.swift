//
//  ActivityStorage.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/31/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

// container for client side cache files that allow simple access to the
// data necessary for a later retry if anything failed on initial send
internal struct ActivityStorage: Codable {
    let accountID: String
    let userID: String
    let requestID: UUID
    let data: Data
    let created: Date
    let userSignature: String?

    // could have a more advanced policy for things like only attempting after x seconds
    var lastAttempt: Date?
    // or only attempting a max X times then clearing from cache
    var numberOfAttempts = 0

    init?(_ activity: Activity) {
        guard let data = try? NetworkClient.encoder.encode(activity) else {
            return nil
        }
        self.accountID = activity.accountID
        self.userID = activity.userID
        self.requestID = activity.requestID
        self.data = data
        self.created = Date()
        self.userSignature = activity.userSignature
    }
}
