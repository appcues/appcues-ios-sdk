//
//  DebugViewModel.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-29.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
internal class DebugViewModel: ObservableObject {
    let accountID: String
    let applicationID: String
    @Published var currentUserID: String {
        didSet {
            userIdentified = !currentUserID.isEmpty
        }
    }
    @Published private(set) var events: [LoggedEvent] = []
    @Published private(set) var trackingPages = false
    @Published private(set) var userIdentified = false
    @Published var isAnonymous = false

    var statusItems: [StatusItem] {
        return [
            StatusItem(
                status: .info,
                title: "\(UIDevice.current.modelName) iOS \(UIDevice.current.systemVersion)",
                subtitle: nil,
                detailText: nil),
            StatusItem(
                status: .verified,
                title: "Installed SDK \(Appcues.version())",
                subtitle: "Account ID: \(accountID)\nApplication ID: \(applicationID)",
                detailText: nil),
            StatusItem(
                status: .verified,
                title: "Connected to Appcues",
                subtitle: nil,
                detailText: nil),
            StatusItem(
                status: trackingPages ? .verified : .pending,
                title: "Tracking Screens",
                subtitle: trackingPages ? nil : "Navigate to another screen to test",
                detailText: nil),
            StatusItem(
                status: userIdentified ? .verified : .unverfied,
                title: "User Identified",
                subtitle: userDescription,
                detailText: currentUserID)
        ]
    }

    private var userDescription: String {
        if userIdentified, isAnonymous {
            return "Anonymous User"
        }
        return currentUserID
    }

    init(accountID: String, applicationID: String, currentUserID: String, isAnonymous: Bool) {
        self.accountID = accountID
        self.applicationID = applicationID
        self.currentUserID = currentUserID
        self.isAnonymous = isAnonymous
        self.userIdentified = !currentUserID.isEmpty
    }

    func reset() {
        trackingPages = false
        currentUserID = ""
        isAnonymous = true
        events.removeAll()
    }

    func addEvent(_ event: LoggedEvent) {
        trackingPages = trackingPages || event.type == .screen
        events.append(event)
    }
}

@available(iOS 13.0, *)
extension DebugViewModel {
    enum Status {
        case verified
        case pending
        case unverfied
        case info

        var symbolName: String {
            switch self {
            case .verified: return "checkmark"
            case .pending: return "ellipsis"
            case .unverfied: return "xmark"
            case .info: return "info.circle"
            }
        }

        var tintColor: Color {
            switch self {
            case .verified: return .green
            case .pending: return .gray
            case .unverfied: return .red
            case .info: return .blue
            }
        }
    }

    struct StatusItem: Identifiable {
        let id = UUID()
        let status: Status
        let title: String
        let subtitle: String?
        let detailText: String?
    }

    struct LoggedEvent: Identifiable {
        typealias Pair = (title: String, value: String?)

        let id = UUID()
        let timestamp: Date
        let type: EventType
        let name: String
        let properties: [String: Any]?

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
            let autoProps = (properties["_identity"] as? [String: Any] ?? [:])
                .sorted { $0.key > $1.key }
                .map { ($0.key, String(describing: $0.value)) }
            properties["_identity"] = nil

            let userProps = properties
                .sorted { $0.key > $1.key }
                .map { ($0.key, String(describing: $0.value)) }

            if !userProps.isEmpty {
                groups.append(("Properties", userProps))
            }

            if !autoProps.isEmpty {
                groups.append(("Identity Auto-properties", autoProps))
            }

            return groups
        }

        init(from update: TrackingUpdate) {
            self.timestamp = update.timestamp
            self.properties = update.properties

            switch update.type {
            case let .event(name, _) where SessionEvents.allNames.contains(name):
                self.type = .sessionEvent
                self.name = name
            case let .event(name, _) where name.starts(with: "appcues:v2:"):
                self.type = .experienceEvent
                self.name = name
            case let .event(name, _):
                self.type = .customEvent
                self.name = name
            case let .screen(title):
                self.type = .screen
                self.name = title
            case .profile:
                self.type = .profile
                self.name = "Profile Update"
            case .group:
                self.type = .group
                self.name = "Group Update"
            }
        }
    }
}

@available(iOS 13.0, *)
extension DebugViewModel.LoggedEvent {
    enum EventType: CustomStringConvertible {
        case screen
        case sessionEvent
        case experienceEvent
        case customEvent
        case profile
        case experience
        case group

        var description: String {
            switch self {
            case .screen: return "Screen"
            case .sessionEvent: return "Session Event"
            case .experienceEvent: return "Experience Event"
            case .customEvent: return "Custom Event"
            case .profile: return "User Profile"
            case .experience: return "Experience"
            case .group: return "Group"
            }
        }

        var symbolName: String {
            switch self {
            case .screen: return "rectangle.portrait.on.rectangle.portrait"
            case .sessionEvent: return "clock.arrow.2.circlepath"
            case .experienceEvent: return "arrow.right.square"
            case .customEvent: return "hand.tap"
            case .profile: return "person"
            case .experience: return "wand.and.stars"
            case .group: return "person.3.fill"
            }
        }
    }
}
