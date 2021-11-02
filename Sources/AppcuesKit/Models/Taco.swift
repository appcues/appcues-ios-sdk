//
//  Taco.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API repsonse stucture for a `sync=1` request and the `/taco` endpoint.
internal struct Taco {
    /// Web modal structure.
    let contents: [Flow]
    /// Mobile experience JSON structure.
    let experiences: [Experience]
    let performedQualification: Bool
}

extension Taco: Decodable {
    private enum CodingKeys: CodingKey {
        case contents
        case experiences
        case performedQualification
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        contents = (try? container.decode([Flow].self, forKey: .contents)) ?? []
        experiences = (try? container.decode([Experience].self, forKey: .experiences)) ?? []

        performedQualification = try container.decode(Bool.self, forKey: .performedQualification)
    }
}
