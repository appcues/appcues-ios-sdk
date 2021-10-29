//
//  TrackingUpdate.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct TrackingUpdate {

    enum TrackingType {
        case event(String)
        case screen(String)
        case profile
    }

    let type: TrackingType
    let properties: [String: Any]?
    let timestamp = Date()
    let userID: String
}

extension TrackingUpdate: CustomStringConvertible {
    var description: String {
        return "TODO: translate for logging / debugger"
    }
}
