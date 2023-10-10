//
//  DebugViewModel.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-29.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, *)
internal class DebugViewModel: ObservableObject {
    private let storage: DataStoring

    // MARK: Navigation
    @Published var navigationDestination: DebugDestination?
    var navigationDestinationIsFonts: Bool {
        get { navigationDestination == .fonts }
        set { navigationDestination = newValue ? .fonts : nil }
    }

    private var events: [LoggedEvent] = []
    let subject = PassthroughSubject<LoggedEvent, Never>()

    // MARK: Status Overview
    let accountID: String
    let applicationID: String
    @Published var currentUserID: String = ""

    @Published var filter: LoggedEvent.EventType?
    var filteredEvents: [LoggedEvent] {
        guard let filter = filter else { return events }
        return events.filter { $0.type == filter }
    }

    @Published var trackingPages = false
    @Published var isAnonymous = false

    @Published var experienceStatuses: [StatusItem] = []
    private let syncQueue = DispatchQueue(label: "appcues-status-listing")

    init(storage: DataStoring, accountID: String, applicationID: String) {
        self.storage = storage
        self.accountID = accountID
        self.applicationID = applicationID
    }

    func reset() {
        filter = nil
        events.removeAll()
        trackingPages = false
        currentUserID = storage.userID
        isAnonymous = storage.isAnonymous
    }

    func removeExperienceStatus(id: UUID) {
        self.experienceStatuses = self.experienceStatuses.filter { $0.id != id }
    }

    // Expects to be called on a background thread.
    private func handleExperienceEvent(properties: LifecycleEvent.EventProperties) {
        var experienceStatuses = experienceStatuses
        let existingIndex = experienceStatuses.firstIndex { $0.id == properties.experienceID }

        let status: StatusItem.Status
        let title: String
        var subtitle: String?

        switch properties.type {
        case .experienceError, .stepError:
            status = .unverified
            title = "Content Omitted: \(properties.experienceName)"
            subtitle = properties.message
        case .stepSeen:
            status = .verified
            title = "Showing \(properties.experienceName)"
            if let stepIndex = properties.stepIndex {
                // Include leading whitespace when needed in this appended string
                let context: String = properties.frameID.flatMap { return " (\($0))" } ?? ""

                // Convert from zero-based to be human readable
                subtitle = "Group \(stepIndex.group + 1) step \(stepIndex.item + 1)\(context)"
            }
        case .stepInteraction, .stepCompleted, .stepRecovered, .experienceStarted, .experienceRecovered:
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

        let updatedStatus = StatusItem(status: status, title: title, subtitle: subtitle, id: properties.experienceID)

        if let existingIndex = existingIndex {
            experienceStatuses[existingIndex] = updatedStatus
        } else {
            experienceStatuses.append(updatedStatus)
        }

        DispatchQueue.main.sync {
            // Errors are listed last
            self.experienceStatuses = experienceStatuses.sorted { $0.status == .verified && $1.status == .unverified }
        }
    }
}

@available(iOS 13.0, *)
extension DebugViewModel: AnalyticsSubscribing {
    func track(update: TrackingUpdate) {
        // Publishing changes must from the main thread.
        DispatchQueue.main.async { [unowned self] in
            self.currentUserID = self.storage.userID
            self.isAnonymous = self.storage.isAnonymous

            let event = LoggedEvent(from: update)
            self.trackingPages = self.trackingPages || event.type == .screen

            if event.type == .experience, let properties = LifecycleEvent.restructure(update: update) {
                // Perform updates sequentially to be safe because the order of the array can change.
                syncQueue.async { [weak self] in
                    self?.handleExperienceEvent(properties: properties)
                }
            }

            events.append(event)

            subject.send(event)
        }
    }
}
