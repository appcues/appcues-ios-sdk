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
    private let networking: Networking

    // MARK: Navigation
    @Published var navigationDestination: DebugDestination?
    var navigationDestinationIsFonts: Bool {
        get { navigationDestination == .fonts }
        set { navigationDestination = newValue ? .fonts : nil }
    }

    // MARK: Recent Events
    @Published private(set) var events: [LoggedEvent] = []
    @Published private(set) var latestEvent: LoggedEvent?

    // MARK: Status Overview
    let accountID: String
    let applicationID: String
    @Published var currentUserID: String {
        didSet {
            userIdentified = !currentUserID.isEmpty
        }
    }
    @Published var filter: DebugViewModel.LoggedEvent.EventType?
    @Published private(set) var connectedStatus = StatusItem(status: .pending, title: "Connected to Appcues")
    @Published private(set) var deeplinkStatus = StatusItem(status: .pending, title: "Appcues Deeplink Configured")
    @Published private(set) var trackingPages = false
    @Published private(set) var userIdentified = false
    @Published var isAnonymous = false

    @Published var experienceStatuses: [StatusItem] = []
    private let syncQueue = DispatchQueue(label: "appcues-status-listing")

    /// Unique value to pass through a deeplink to verify handling.
    private var deeplinkVerificationToken: String?

    var statusItems: [StatusItem] {
        return [
            StatusItem(
                status: .info,
                title: "\(UIDevice.current.modelName) iOS \(UIDevice.current.systemVersion)"),
            StatusItem(
                status: .verified,
                title: "Installed SDK \(Appcues.version())",
                subtitle: "Account ID: \(accountID)\nApplication ID: \(applicationID)"),
            connectedStatus,
            deeplinkStatus,
            StatusItem(
                status: trackingPages ? .verified : .pending,
                title: "Tracking Screens",
                subtitle: trackingPages ? nil : "Navigate to another screen to test"),
            StatusItem(
                status: userIdentified ? .verified : .unverfied,
                title: "User Identified",
                subtitle: userDescription,
                detailText: currentUserID)
        ] + experienceStatuses
    }

    private var userDescription: String {
        if userIdentified, isAnonymous {
            return "Anonymous User"
        }
        return currentUserID
    }

    init(networking: Networking, accountID: String, applicationID: String, currentUserID: String, isAnonymous: Bool) {
        self.networking = networking
        self.accountID = accountID
        self.applicationID = applicationID
        self.currentUserID = currentUserID
        self.isAnonymous = isAnonymous
        self.userIdentified = !currentUserID.isEmpty

        connectedStatus.action = Action(symbolName: "arrow.triangle.2.circlepath") { [weak self] in self?.ping() }
        deeplinkStatus.action = Action(symbolName: "arrow.triangle.2.circlepath") { [weak self] in self?.verifyDeeplink() }
    }

    func reset() {
        filter = nil
        events.removeAll()
        latestEvent = nil
        trackingPages = false
    }

    // MARK: Event Handling

    func addUpdate(_ update: TrackingUpdate) {
        let event = LoggedEvent(from: update)

        trackingPages = trackingPages || event.type == .screen

        latestEvent = event

        if event.type == .experience, let properties = LifecycleEvent.restructure(update: update) {
            // Perform updates sequentially to be safe because the order of the array can change.
            syncQueue.async { [weak self] in
                self?.handleExperienceEvent(properties: properties)
            }
        }

        events.append(event)
    }

    // Expects to be called on a background thread.
    private func handleExperienceEvent(properties: LifecycleEvent.EventProperties) {
        var experienceStatuses = experienceStatuses
        let existingIndex = experienceStatuses.firstIndex { $0.id == properties.experienceID }

        let status: Status
        let title: String
        var subtitle: String?
        var action: Action?

        switch properties.type {
        case .experienceError, .stepError:
            status = .unverfied
            title = "Content Omitted: \(properties.experienceName)"
            if let message = properties.message {
                subtitle = message
            }
            // Add a dismiss button to remove the row. Non-error rows are automatically removed when the experience completes.
            action = Action(symbolName: "xmark") { [weak self] in
                guard let self = self else { return }
                self.experienceStatuses = self.experienceStatuses.filter { $0.id != properties.experienceID }
            }
        case .stepSeen:
            status = .verified
            title = "Showing \(properties.experienceName)"
            if let stepIndex = properties.stepIndex {
                // Convert from zero-based to be human readable
                subtitle = "Group \(stepIndex.group + 1) step \(stepIndex.item + 1)"
            }
        case .stepInteraction, .stepCompleted, .stepRecovered, .experienceStarted:
            status = .verified
            title = "Showing \(properties.experienceName)"
        case .experienceCompleted, .experienceDismissed:
            if let existingIndex = existingIndex {
                DispatchQueue.main.sync {
                    _ = self.experienceStatuses.remove(at: existingIndex)
                }
            }
            return
        }

        let updatedStatus = StatusItem(status: status, title: title, subtitle: subtitle, id: properties.experienceID, action: action)

        if let existingIndex = existingIndex {
            experienceStatuses[existingIndex] = updatedStatus
        } else {
            experienceStatuses.append(updatedStatus)
        }

        DispatchQueue.main.sync {
            // Errors are listed last
            self.experienceStatuses = experienceStatuses.sorted { $0.status == .verified && $1.status == .unverfied }
        }
    }

    // MARK: API Connection Status

    func ping() {
        connectedStatus.status = .pending
        connectedStatus.subtitle = nil
        connectedStatus.detailText = nil

        networking.get(from: APIEndpoint.health) { [weak self] (result: Result<ActivityResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.connectedStatus.status = .verified
                case .failure(let error):
                    self?.connectedStatus.status = .unverfied
                    self?.connectedStatus.subtitle = error.localizedDescription
                    self?.connectedStatus.detailText = "\(error)"
                }
            }
        }
    }

    // MARK: Deeplink Status

    func verifyDeeplink() {
        deeplinkStatus.status = .pending
        deeplinkStatus.subtitle = nil

        if !infoPlistContainsScheme() {
            deeplinkStatus.status = .unverfied
            deeplinkStatus.subtitle = "Error 1: CFBundleURLSchemes value missing"
            return
        }

        verifyDeeplinkHandling(token: UUID().uuidString)
    }

    private func infoPlistContainsScheme() -> Bool {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else { return false }

        return urlTypes
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
            .contains { $0 == "appcues-\(applicationID)" }
    }

    private func verifyDeeplinkHandling(token: String) {
        guard let url = URL(string: "appcues-\(applicationID)://sdk/verify/\(token)") else {
            deeplinkStatus.status = .unverfied
            deeplinkStatus.subtitle = "Error 0: Failed to set up verification"
            return
        }

        deeplinkVerificationToken = token

        UIApplication.shared.open(url, options: [:])

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.deeplinkVerificationToken != nil {
                self.deeplinkStatus.status = .unverfied
                self.deeplinkStatus.subtitle = "Error 2: Appcues SDK not receiving links"
                self.deeplinkVerificationToken = nil
            }
        }
    }

    func receivedVerification(token: String) {
        if token == deeplinkVerificationToken {
            deeplinkStatus.status = .verified
            deeplinkStatus.subtitle = nil
        } else {
            deeplinkStatus.status = .unverfied
            deeplinkStatus.subtitle = "Error 3: Unexpected result"
        }

        deeplinkVerificationToken = nil
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

    struct Action {
        let symbolName: String
        let block: () -> Void
    }

    struct StatusItem: Identifiable {
        let id: UUID
        var status: Status
        let title: String
        var subtitle: String?
        var detailText: String?
        var action: Action?

        init(
            status: DebugViewModel.Status,
            title: String,
            subtitle: String? = nil,
            detailText: String? = nil,
            id: UUID = UUID(),
            action: DebugViewModel.Action? = nil
        ) {
            self.id = id
            self.status = status
            self.title = title
            self.subtitle = subtitle
            self.detailText = detailText
            self.action = action
        }
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
                .sortedWithAutoProperties()
                .map { ($0.key, String(describing: $0.value)) }
            properties["_identity"] = nil

            let userProps = properties
                .sortedWithAutoProperties()
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
                self.type = .session
                self.name = name.prettifiedEventName
            case let .event(name, _) where name.starts(with: "appcues:v2:"):
                self.type = .experience
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
    var prettifiedEventName: String {
        self
            .split(separator: ":")
            .last?
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ") ?? self
    }
}

@available(iOS 13.0, *)
extension DebugViewModel.LoggedEvent {
    enum EventType: CaseIterable, CustomStringConvertible {
        case screen
        case custom
        case profile
        case group
        case session
        case experience

        var description: String {
            switch self {
            case .screen: return "Screen"
            case .custom: return "Custom"
            case .profile: return "User Profile"
            case .group: return "Group"
            case .session: return "Session"
            case .experience: return "Experience"
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
            }
        }
    }
}
