//
//  AnalyticsBroadcaster.swift
//  AppcuesKit
//
//  Created by James Ellis on 6/27/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

// A class that listens to analytic events in the system and broadcasts
// them to the host application delegate, if one is optionally attached.
internal class AnalyticsBroadcaster: AnalyticsSubscribing {

    private weak var appcues: Appcues?
    private let publisher: AnalyticsPublishing
    private let storage: DataStoring

    init(container: DIContainer) {
        self.appcues = container.owner
        self.publisher = container.resolve(AnalyticsPublishing.self)
        self.storage = container.resolve(DataStoring.self)
    }

    func track(update: TrackingUpdate) {
        guard let delegate = appcues?.analyticsDelegate else { return }

        switch update.type {
        case let .event(name, _):
            delegate.didTrack(analytic: .event, value: name, properties: update.properties, isInternal: update.isInternal)
        case let .screen(title):
            delegate.didTrack(analytic: .screen, value: title, properties: update.properties, isInternal: update.isInternal)
        case let .group(groupID):
            delegate.didTrack(analytic: .group, value: groupID, properties: update.properties, isInternal: update.isInternal)
        case .profile:
            delegate.didTrack(analytic: .identify, value: storage.userID, properties: update.properties, isInternal: update.isInternal)
        }
    }
}
