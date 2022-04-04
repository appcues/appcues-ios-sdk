//
//  QualifyResponse.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API repsonse stucture for a `/qualify` request.
internal struct QualifyResponse {
    /// Mobile experience JSON structure.
    let experiences: [Experience]
    let performedQualification: Bool
}

extension QualifyResponse: Decodable {
    private enum CodingKeys: CodingKey {
        case experiences
        case performedQualification
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experiences = try container.decode([Experience].self, forKey: .experiences)
        performedQualification = try container.decode(Bool.self, forKey: .performedQualification)
    }
}
