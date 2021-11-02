//
//  Taco.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API repsonse stucture for a `sync=1` request and the `/taco` endpoint.
internal struct Taco: Decodable {
    let contents: [Flow]
    let performedQualification: Bool
}
