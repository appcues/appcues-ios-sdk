//
//  LoggedEvent.swift
//  AppcuesKit
//
//  Created by Matt on 2023-09-27.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal struct LoggedEvent: Identifiable {
    typealias Pair = (title: String, value: String?)

    let id = UUID()
    let timestamp: Date
    let type: EventType
    let name: String
    let properties: [String: Any]?

    let structuredLifecycleProperties: StructuredLifecycleProperties?

    var eventDetailItems: [Pair] {
        [
            ("Type", type.description),
            ("Name", name),
            ("Timestamp", "\(timestamp)")
        ]
    }

    var eventProperties: [(title: String, items: [Pair])]? {
        guard var properties = properties else { return nil }

        var groups: [(title: String, items: [Pair])] = []

        // flatten the nested `_identity` auto-properties into individual top level items.
        let identityAutoProps = (properties["_identity"] as? [String: Any] ?? [:])
            .sortedWithAutoProperties()
            .map { ($0.key, String(describing: $0.value)) }
        properties["_identity"] = nil

        // flatten the nested `_device` auto-properties into individual top level items.
        let deviceAutoProps = (properties["_device"] as? [String: Any] ?? [:])
            .sortedWithAutoProperties()
            .map { ($0.key, String(describing: $0.value)) }
        properties["_device"] = nil

        // flatten the nested `_sdkMetrics` properties into individual top level items.
        let metricProps = (properties["_sdkMetrics"] as? [String: Any] ?? [:])
            .sortedWithAutoProperties()
            .map { ($0.key, String(describing: $0.value)) }
        properties["_sdkMetrics"] = nil

        // flatten the nested `interactionData` properties into individual top level items.
        var interactionData = (properties["interactionData"] as? [String: Any] ?? [:])
        let formResponse = (interactionData["formResponse"] as? ExperienceData.StepState)?.formattedAsDebugData()
        interactionData["formResponse"] = nil
        properties["interactionData"] = nil
        let interactionProps = interactionData
            .sortedWithAutoProperties()
            .map { ($0.key, String(describing: $0.value)) }

        let userProps = properties
            .sortedWithAutoProperties()
            .map { ($0.key, String(describing: $0.value)) }

        if !userProps.isEmpty {
            groups.append(("Properties", userProps))
        }

        // Other types of interaction data
        if !interactionProps.isEmpty {
            groups.append(("Interaction Data", interactionProps))
        }

        if let formResponse = formResponse, !formResponse.isEmpty {
            groups.append(("Interaction Data: Form Response", formResponse))
        }

        if !identityAutoProps.isEmpty {
            groups.append(("Identity Auto-properties", identityAutoProps))
        }

        if !deviceAutoProps.isEmpty {
            groups.append(("Device Auto-properties", deviceAutoProps))
        }

        if !metricProps.isEmpty {
            groups.append(("SDK Metrics", metricProps))
        }

        return groups
    }

    init(from update: TrackingUpdate) {
        self.timestamp = update.timestamp
        self.properties = update.properties

        switch update.type {
        case let .event(name, _) where Events.Session(rawValue: name) != nil:
            self.type = .session
            self.name = name.prettifiedEventName
        case let .event(name, _) where Events.Experience(rawValue: name) != nil:
            self.type = .experience
            self.name = name.prettifiedEventName
        case let .event(name, _) where Events.Device(rawValue: name) != nil:
            self.type = .device
            self.name = name.prettifiedEventName
        case let .event(name, _) where Events.Push(rawValue: name) != nil:
            self.type = .push
            self.name = name.prettifiedEventName
        case let .event(name, _):
            self.type = .custom
            self.name = name
        case let .screen(title):
            self.type = .screen
            self.name = title
        case .profile:
            self.type = .profile
            self.name = "\(update.properties?["userId"] ?? "Profile Update")"
        case let .group(groupID):
            self.type = .group
            self.name = "\(groupID ?? "-")"
        }

        self.structuredLifecycleProperties = StructuredLifecycleProperties(update: update)
    }
}

extension LoggedEvent {
    enum EventType: CaseIterable, CustomStringConvertible {
        case screen
        case custom
        case profile
        case group
        case session
        case experience
        case device
        case push

        var description: String {
            switch self {
            case .screen: return "Screen"
            case .custom: return "Custom"
            case .profile: return "User Profile"
            case .group: return "Group"
            case .session: return "Session"
            case .experience: return "Experience"
            case .device: return "Device"
            case .push: return "Push"
            }
        }

        var symbolName: String {
            switch self {
            case .screen: return "rectangle.portrait.on.rectangle.portrait"
            case .custom: return "hand.tap"
            case .profile: return "person"
            case .group: return "person.3"
            case .session: return "clock.arrow.2.circlepath"
            case .experience: return "arrow.right.square"
            case .device: return "iphone"
            case .push: return "bell.badge"
            }
        }
    }
}

private extension Dictionary where Key == String, Value == Any {
    func sortedWithAutoProperties() -> [(key: Key, value: Value)] {
        self.sorted {
            switch ($0.key.first, $1.key.first) {
            case ("_", "_"):
                return $0.key <= $1.key
            case ("_", _):
                return false
            case (_, "_"):
                return true
            default:
                return $0.key <= $1.key
            }
        }
    }
}

private extension String {
    /// Convert something like "appcues:v2:step_seen" to "Step Seen"
    var prettifiedEventName: String {
        self
            .split(separator: ":")
            .last?
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ") ?? self
    }
}
