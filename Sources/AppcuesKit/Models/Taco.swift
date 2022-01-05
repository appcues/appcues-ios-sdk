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

    // Note: calls without `sync=1` do not include items above on response, just "ok": true
    //       thus, all are marked optional for successful parse of the response regardless
    let ok: String?
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

        contents = (try? container.decode([Flow].self, forKey: .contents)) ?? []
        experiences = (try? container.decode([Experience].self, forKey: .experiences)) ?? []
        performedQualification = (try? container.decode(Bool.self, forKey: .performedQualification)) ?? false
        ok = try? container.decode(String.self, forKey: .ok)
    }
}
