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
        case group
    }

    let type: TrackingType
    var properties: [String: Any]?
    let timestamp = Date()
}

extension TrackingUpdate: CustomStringConvertible {
    var description: String {
        return "TODO: translate for logging / debugger"
    }
}
