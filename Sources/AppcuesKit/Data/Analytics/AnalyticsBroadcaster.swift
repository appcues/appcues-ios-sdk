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
    private let storage: DataStoring

    init(container: DIContainer) {
        self.appcues = container.owner
        self.storage = container.resolve(DataStoring.self)
    }

    func track(update: TrackingUpdate) {
        guard let delegate = appcues?.analyticsDelegate else { return }

        var properties = update.properties
        properties?.values.sanitize()

        switch update.type {
        case let .event(name, _):
            delegate.didTrack(analytic: .event, value: name, properties: properties, isInternal: update.isInternal)
        case let .screen(title):
            delegate.didTrack(analytic: .screen, value: title, properties: properties, isInternal: update.isInternal)
        case let .group(groupID):
            delegate.didTrack(analytic: .group, value: groupID, properties: properties, isInternal: update.isInternal)
        case .profile:
            delegate.didTrack(analytic: .identify, value: storage.userID, properties: properties, isInternal: update.isInternal)
        }
    }
}

// Implemented an extension on MutableCollection rather than duplicating code for Dictionary<String, Any> and Array<Any>.
private extension MutableCollection where Element == Any {
    /// Transform a collection of properties to be standardized for consumption outside the SDK.
    ///
    /// In-place sanitizing of the MutableCollection values.
    /// It's required to be this way because Dictionary doesn't conform to MutableCollection, only Dictionary.Values.
    mutating func sanitize() {
        for key in self.indices {
            if let stepState = self[key] as? ExperienceData.StepState {
                // Setting this outside the switch means the switch applies to the dictionary value, ensuring it's also sanitized.
                self[key] = stepState.formattedAsAny() ?? NSNull()
            }

            switch self[key] {
            case let date as Date:
                self[key] = date.millisecondsSince1970
            case var dict as [String: Any]:
                dict.values.sanitize()
                self[key] = dict
            case var arr as [Any]:
                arr.sanitize()
                self[key] = arr
            default:
                break
            }
        }
    }
}
