//
//  PushRequest.swift
//  AppcuesKit
//
//  Created by Matt on 2024-03-18.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation

internal struct PushRequest {
    let deviceID: String
    let additionalData: [String: Any]

    init(deviceID: String, queryItems: [URLQueryItem] = []) {
        self.deviceID = deviceID
        self.additionalData = queryItems.reduce(into: [:]) { result, item in
            if let value = item.value {
                result[item.name] = value
            }
        }
    }
}

extension PushRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
    }

    func encode(to encoder: Encoder) throws {
        var dynamicContainer = encoder.container(keyedBy: DynamicCodingKeys.self)
        try dynamicContainer.encodeSkippingInvalid(additionalData)

        // Encode device_id last just to ensure it wins in case the query items have the same key
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.deviceID, forKey: .deviceID)
    }
}
