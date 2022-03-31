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
    func flush()
}

internal class AnalyticsTracker: AnalyticsTracking, AnalyticsSubscribing {

    private static let flushAfterSeconds: Double = 10

    private let container: DIContainer

    private lazy var storage = container.resolve(DataStoring.self)
    private lazy var config = container.resolve(Appcues.Config.self)
    private lazy var activityProcessor = container.resolve(ActivityProcessing.self)

    @available(iOS 13.0, *)
    private lazy var experienceRenderer = container.resolve(ExperienceRendering.self)

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
                flushPendingActivity()
            }

        case .flushThenSend:
            syncQueue.sync {
                flushWorkItem?.cancel()
                flushPendingActivity()
                flush(activity)
            }

        case .queue:
            syncQueue.sync {
                pendingActivity.append(activity)
                if flushWorkItem == nil {
                    let workItem = DispatchWorkItem { [weak self] in
                        self?.syncQueue.sync {
                            self?.flushPendingActivity()
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
    func flush() {
        syncQueue.sync {
            flushPendingActivity()
        }
    }

    private func flushPendingActivity() {
        flushWorkItem = nil
        let merged = pendingActivity.merge()
        pendingActivity = []
        flush(merged)
    }

    private func flush(_ activity: Activity?) {
        guard let activity = activity else { return }
        activityProcessor.process(activity) { [weak self] result in
            switch result {
            case .success(let taco):
                if #available(iOS 13.0, *) {
                    self?.experienceRenderer.show(qualifiedExperiences: taco.experiences, completion: nil)
                } else {
                    self?.config.logger.info("iOS 13 or above is required to render an Appcues experience")
                }
            case .failure(let error):
                self?.config.logger.error("%{public}s", "\(error)")
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
                      profileUpdate: update.eventAutoProperties,
                      groupID: storage.groupID)

        case let .screen(title):
            self.init(accountID: config.accountID,
                      userID: storage.userID,
                      events: [Event(screen: title, attributes: update.properties, context: update.context)],
                      profileUpdate: update.eventAutoProperties,
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

            // additional events can also cause autoproperty updates, merge those in
            newEvents.forEach {
                if let autoProps = $0.autoProperties {
                    profileUpdate = (profileUpdate ?? [:]).merging(autoProps) { _, new in new }
                }
            }
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
