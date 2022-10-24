//
//  Experiment.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/17/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal struct Experiment {
    let group: String
    let experimentID: UUID
    let experienceID: UUID

    var shouldExecute: Bool {
        return group != "control"
    }
}

extension Experiment: Decodable {
    private enum CodingKeys: String, CodingKey {
        case group
        case experimentID = "experimentId"
        case experienceID = "experienceId"
    }
}
