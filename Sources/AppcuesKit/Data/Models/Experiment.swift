//
//  Experiment.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/17/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal struct Experiment: Decodable {
    let group: String
}

extension Experiment {
    func shouldExecute() -> Bool {
        return group != "control"
    }

    func track(appcues: Appcues?, experimentID: String?) {
        guard let experimentID = experimentID,
              let analyticsPublisher = appcues?.container.resolve(AnalyticsPublishing.self) else { return }

        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: "appcues:experiment_entered", interactive: false),
            properties: [
                "experimentId": experimentID,
                "group": group
            ],
            isInternal: true))
    }
}
