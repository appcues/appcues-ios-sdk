//
//  Experiment.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/17/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal struct Experiment: Decodable {

    enum ExperimentGroup: String, Decodable {
        case control
        case exposed
    }

    // making this optional so an unknown experiment group does not fail
    // the entire qualify response deserialization
    let group: ExperimentGroup?
}
