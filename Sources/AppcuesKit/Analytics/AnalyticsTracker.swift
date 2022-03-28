//
//  AnalyticsTracker.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal protocol AnalyticsTracking {
    func flushAsync()
}

internal class AnalyticsTracker: AnalyticsTracking, AnalyticsSubscribing {

    private static let flushAfterSeconds: Double = 10

    private let container: DIContainer

    private lazy var storage = container.resolve(DataStoring.self)
    private lazy var config = container.resolve(Appcues.Config.self)
    private lazy var experienceRenderer = container.resolve(ExperienceRendering.self)
    private lazy var activityProcessor = container.resolve(ActivityProcessing.self)

    // maintain a batch of asynchronous events that are waiting to be flushed to network
    private let syncQueue = DispatchQueue(label: "appcues-analytics")
    private var pendingActivity: [Activity] = []
    private var flushWorkItem: DispatchWorkItem?

    init(container: DIContainer) {
        self.container = container
    }

    func track(update: TrackingUpdate) {
        let activity = Activity(from: update, config: config, storage: storage)

        switch update.policy {
        case .queueThenFlush:
            syncQueue.sync {
                flushWorkItem?.cancel()
                pendingActivity.append(activity)
                flushPendingActivity(sync: true)
            }

        case .flushThenSend:
            syncQueue.sync {
                flushWorkItem?.cancel()
                flushPendingActivity(sync: false)
                flush(activity, sync: true)
            }

        case .queue:
            syncQueue.sync {
                pendingActivity.append(activity)
                if flushWorkItem == nil {
                    let workItem = DispatchWorkItem { [weak self] in
                        self?.syncQueue.sync {
                            self?.flushPendingActivity(sync: false)
                        }
                    }
                    flushWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + AnalyticsTracker.flushAfterSeconds, execute: workItem)
                }
            }
        }
    }

    // to be called when any pending activity should immediately be flushed to cache, and network if possible
    // i.e. app going to background / being killed
    func flushAsync() {
        flushPendingActivity(sync: false)
    }

    private func flushPendingActivity(sync: Bool) {
        flushWorkItem = nil
        let merged = pendingActivity.merge()
        pendingActivity = []
        flush(merged, sync: sync)
    }

    private func flush(_ activity: Activity?, sync: Bool) {
        guard let activity = activity else { return }
        activityProcessor.process(activity, sync: sync) { [weak self] result in
            guard sync, let experienceRenderer = self?.experienceRenderer else { return }
            switch result {
            case .success(let taco):
                experienceRenderer.show(qualifiedExperiences: taco.experiences, completion: nil)
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension Activity {
    init(from update: TrackingUpdate, config: Appcues.Config, storage: DataStoring) {
        switch update.type {
        case let .event(name, _):
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: [Event(name: name, attributes: update.properties, context: update.context)],
                      groupID: storage.groupID)

        case let .screen(title):
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: [Event(screen: title, attributes: update.properties, context: update.context)],
                      groupID: storage.groupID)

        case .profile:
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: nil,
                      profileUpdate: update.properties,
                      groupID: storage.groupID)

        case .group:
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: nil,
                      groupID: storage.groupID,
                      groupUpdate: update.properties)
        }
    }

    mutating func append(_ activity: Activity) {
        // the only thing we support merging here is additional events.
        // if the user or group, or any associated user or group properties are updated,
        // those cause any pending activity to be flushed, then the user or group
        // activity immediately flushed as an individual item - there is no concept
        // of merging content across user or group updates.  The reason is that the
        // activity prior to that update needs to be associated to the correct user/group
        // and the activity after that update needs to be associated with the new user/group
        if let newEvents = activity.events {
            let existingEvents = events ?? []
            events = existingEvents + newEvents
        }
    }
}

private extension Array where Element == Activity {
    mutating func merge() -> Activity? {
        // if size is zero or one, return first - which is either nil or the single element
        guard let first = first, count > 1 else { return first }
        let additional = suffix(from: 1)
        let merged = additional.reduce(into: first) { accumulating, update  in
            accumulating.append(update)
        }
        return merged
    }
}
