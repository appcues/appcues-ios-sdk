//
//  SdkSettings.swift
//  AppcuesKit
//
//  Created by James Ellis on 2/15/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

// The response model for the Appcues settings endpoint,
// http://fast.appcues.com/bundle/accounts/{account_id}/mobile/settings.
// Provides the path to customer API to use for screen capture features.
internal struct SdkSettings: Decodable {

    struct Services: Decodable {
        let customerApi: String
    }

    let services: Services
}
