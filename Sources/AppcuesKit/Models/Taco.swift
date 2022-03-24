//
//  Taco.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API repsonse stucture for an `/activity` request and the `/taco` endpoint.
internal struct Taco {
    /// Mobile experience JSON structure.
    let experiences: [Experience]
    let performedQualification: Bool
}

extension Taco: Decodable {
    private enum CodingKeys: CodingKey {
        case contents
        case experiences
        case performedQualification
        case ok
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        experiences = (try? container.decode([Experience].self, forKey: .experiences)) ?? []

        if container.allKeys.contains(.ok) {
            // a reponse with only "ok" is the case when the `sync=1` param is not included - no
            // syncronous qualification, just internal analytics data
            performedQualification = false
        } else {
            performedQualification = try container.decode(Bool.self, forKey: .performedQualification)
        }
    }
}
