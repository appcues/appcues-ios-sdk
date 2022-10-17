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

    enum QualificationReason: String, Decodable {
        case forced = "forced"
        case eventTrigger = "event_trigger"
        case pageView = "page_view"
        case screenView = "screen_view"
    }

    /// Mobile experience JSON structure.
    let experiences: [Experience]
    let performedQualification: Bool
    let qualificationReason: QualificationReason?
    let experiments: [String: Experiment]?
}

extension QualifyResponse: Decodable {
    private enum CodingKeys: CodingKey {
        case experiences
        case performedQualification
        case qualificationReason
        case experiments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experiences = try container.decode([Experience].self, forKey: .experiences)
        performedQualification = try container.decode(Bool.self, forKey: .performedQualification)
        // Optional try so that an unknown reason is treated as nil rather than failing the decode.
        qualificationReason = try? container.decode(QualificationReason.self, forKey: .qualificationReason)
        experiments = try? container.decode([String: Experiment].self, forKey: .experiments)
    }
}
