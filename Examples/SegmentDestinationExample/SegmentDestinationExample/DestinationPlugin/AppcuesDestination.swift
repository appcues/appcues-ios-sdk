//
//  AppcuesDestination.swift
//  SegmentDestinationExample
//
//  Created by James Ellis on 10/13/21.
//

import Foundation
import Segment
import Appcues

private struct AppcuesSettings: Codable {
    let appcuesId: String
}

/// An implementation of the Appcues device mode destination as a plugin.
public class AppcuesDestination: DestinationPlugin {
    public let timeline = Timeline()
    public let key = "Appcues"
    public let type = PluginType.destination
    public var analytics: Analytics?

    public private(set) var appcues: Appcues?

    public func update(settings: Settings, type: UpdateType) {
        guard let appcuesSettings: AppcuesSettings = settings.integrationSettings(forPlugin: self) else { return }
        appcues = Appcues(config: Config(accountID: appcuesSettings.appcuesId))
    }

    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        if let appcues = appcues, let userId = event.userId {
            appcues.identify(userID: userId, properties: event.traits?.appcuesProperties)
        }
        return event
    }

    public func track(event: TrackEvent) -> TrackEvent? {
        if let appcues = appcues {
            appcues.track(event: event.event, properties: event.properties?.appcuesProperties)
        }
        return event
    }

    public func screen(event: ScreenEvent) -> ScreenEvent? {
        if let appcues = appcues, let title = event.name  {
            appcues.screen(title: title, properties: event.properties?.appcuesProperties)
        }
        return event
    }
}

private extension JSON {
    // We need to build support for [String: Any] properties, converting to strings for now.
    // Also note: https://docs.appcues.com/article/161-javascript-api
    //   Property values can be strings, numbers, or booleans. Beware!
    //   Any identify call with an array or nested object as a property
    //   value will not appear in your Appcues account.
    var appcuesProperties: [String: String]? {
        guard let properties = dictionaryValue else { return nil }
        var converted: [String: String] = [:]
        for (key, value) in properties {
            converted[key] = "\(value)"
        }
        return converted
    }
}
