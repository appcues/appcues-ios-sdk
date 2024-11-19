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

internal class DebugViewModel: ObservableObject {
    private let storage: DataStoring
    private var cancellables = Set<AnyCancellable>()

    // MARK: Navigation
    @Published var navigationDestination: DebugDestination?
    var navigationDestinationIsFonts: Bool {
        get { navigationDestination == .fonts }
        set { navigationDestination = newValue ? .fonts : nil }
    }
    var navigationDestinationIsPlugins: Bool {
        get { navigationDestination == .plugins }
        set { navigationDestination = newValue ? .plugins : nil }
    }

    private var events: [LoggedEvent] = []

    // MARK: Status Overview
    let accountID: String
    let applicationID: String
    @Published var currentGroupID: String?
    @Published var currentUserID: String = ""
    @Published var isAnonymous = false
    @Published var trackingPages = false

    @Published var filter: LoggedEvent.EventType?
    var filteredEvents: [LoggedEvent] {
        guard let filter = filter else { return events }
        return events.filter { $0.type == filter }
    }

    @Published var experienceStatuses: [StatusItem] = []

    init(eventPublisher: AnyPublisher<LoggedEvent, Never>, storage: DataStoring, accountID: String, applicationID: String) {
        self.storage = storage
        self.accountID = accountID
        self.applicationID = applicationID

        self.currentGroupID = storage.groupID
        self.currentUserID = storage.userID
        self.isAnonymous = storage.isAnonymous

        // Subscriber to update the experience status list
        eventPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] in
                self?.mapToExperienceStatusList(event: $0)
            }
            .sink { [weak self] statuses in
                self?.experienceStatuses = statuses
            }
            .store(in: &cancellables)

        eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let strongSelf = self else { return }
                strongSelf.currentGroupID = storage.groupID
                strongSelf.currentUserID = storage.userID
                strongSelf.isAnonymous = storage.isAnonymous
                strongSelf.trackingPages = strongSelf.trackingPages || event.type == .screen
                strongSelf.events.append(event)
            }
            .store(in: &cancellables)
    }

    func reset() {
        filter = nil
        events.removeAll()
        trackingPages = false
        currentUserID = storage.userID
        isAnonymous = storage.isAnonymous
        currentGroupID = storage.groupID
    }

    func removeExperienceStatus(id: UUID) {
        self.experienceStatuses = self.experienceStatuses.filter { $0.id != id }
    }

    private func mapToExperienceStatusList(event: LoggedEvent) -> [StatusItem]? {
        guard let properties = event.structuredLifecycleProperties else { return nil }

        var statuses = experienceStatuses
        let existingIndex = statuses.firstIndex { $0.id == properties.experienceID }

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
                statuses.remove(at: existingIndex)
            }
            return statuses
        }

        let updatedStatus = StatusItem(status: status, title: title, subtitle: subtitle, id: properties.experienceID)

        if let existingIndex = existingIndex {
            statuses[existingIndex] = updatedStatus
        } else {
            statuses.append(updatedStatus)
        }

        // Errors are listed last
        return statuses.sorted { $0.status == .verified && $1.status == .unverified }
    }
}
