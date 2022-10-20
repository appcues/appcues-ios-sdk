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
    let experimentID: String
}

extension Experiment: Decodable {
    private enum CodingKeys: String, CodingKey {
        case group
        case experimentID = "experimentId"
    }
}

extension Experiment {
    func shouldExecute() -> Bool {
        return group != "control"
    }

    func track(appcues: Appcues?) {
        guard let analyticsPublisher = appcues?.container.resolve(AnalyticsPublishing.self) else { return }

        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: "appcues:experiment_entered", interactive: false),
            properties: [
                "experimentId": experimentID,
                "group": group
            ],
            isInternal: true))
    }
}
