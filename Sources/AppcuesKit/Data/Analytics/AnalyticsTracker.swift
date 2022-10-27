//
//  AnalyticsTracker.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsTracking: AnyObject {
    func flush()
}

internal class AnalyticsTracker: AnalyticsTracking, AnalyticsSubscribing {

    private static let flushAfterSeconds: Double = 10

    private let storage: DataStoring
    private let config: Appcues.Config
    private let activityProcessor: ActivityProcessing

    // A weak reference to ExperienceRendering would be expected here to avoid a retain cycle with AnalyticsObserver +
    // AnalyticsPublishing, except because ExperienceRendering requires iOS 13, it'd have to be lazy and lazy + weak
    // doesn't work. Instead weakly reference the container and resolve ExperienceRendering on demand to avoid a cycle
    // with AnalyticsPublishing.
    private weak var container: DIContainer?

    // maintain a batch of asynchronous events that are waiting to be flushed to network
    private let syncQueue = DispatchQueue(label: "appcues-analytics")
    private var pendingActivity: [Activity] = []
    private var flushWorkItem: DispatchWorkItem?

    init(container: DIContainer) {
        self.storage = container.resolve(DataStoring.self)
        self.config = container.resolve(Appcues.Config.self)
        self.activityProcessor = container.resolve(ActivityProcessing.self)
        self.container = container
    }

    func track(update: TrackingUpdate) {
        let activity = Activity(from: update, config: config, storage: storage)

        switch update.policy {
        case .queueThenFlush:
            syncQueue.sync {
                flushWorkItem?.cancel()
                pendingActivity.append(activity)
                flushPendingActivity(trackedAt: update.timestamp) // immediately flush, eligible for qualification, so track timing
            }

        case .flushThenSend:
            syncQueue.sync {
                flushWorkItem?.cancel()
                flushPendingActivity() // no timing tracking on pending background activity
                flush(activity, trackedAt: update.timestamp) // immediately flush, eligible for qualification, so track timing
            }

        case .queue:
            syncQueue.sync {
                pendingActivity.append(activity)
                if flushWorkItem == nil {
                    let workItem = DispatchWorkItem { [weak self] in
                        self?.syncQueue.sync {
                            self?.flushPendingActivity() // no timing tracking on background actvity flush
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

    private func flushPendingActivity(trackedAt: Date? = nil) {
        flushWorkItem = nil
        let merged = pendingActivity.merge()
        pendingActivity = []
        flush(merged, trackedAt: trackedAt)
    }

    private func flush(_ activity: Activity?, trackedAt: Date?) {
        guard let activity = activity else { return }
        // `trackedAt` value is only sent in cases of immediate qualification-eligible tracking, for SDK metrics
        SdkMetrics.tracked(activity.requestID, time: trackedAt)
        activityProcessor.process(activity) { [weak self] result in
            switch result {
            case .success(let qualifyResponse):
                if !qualifyResponse.experiences.isEmpty {
                    if #available(iOS 13.0, *) {
                        self?.process(qualifyResponse: qualifyResponse, activity: activity)
                    } else {
                        self?.config.logger.info("iOS 13 or above is required to render an Appcues experience")
                        // nothing will render, we can remove tracking
                        SdkMetrics.remove(activity.requestID)
                    }
                } else {
                    // common case, nothing qualified - we know there was nothing to render, so just remove tracking
                    SdkMetrics.remove(activity.requestID)
                }
            case .failure(let error):
                self?.config.logger.error("Failed processing qualify response: %{public}s", "\(error)")
                SdkMetrics.remove(activity.requestID)
            }
        }
    }

    @available(iOS 13.0, *)
    private func process(qualifyResponse: QualifyResponse, activity: Activity) {
        if let experienceRenderer = container?.resolve(ExperienceRendering.self) {
            let experiments = qualifyResponse.experiments ?? []
            let qualifiedExperienceData: [ExperienceData] = qualifyResponse.experiences.map { experience in
                let experiment = experiments.first { $0.experienceID == experience.id }
                return ExperienceData(experience,
                                      triggeredBy: .qualification(reason: qualifyResponse.qualificationReason?.rawValue),
                                      priority: qualifyResponse.renderPriority,
                                      published: true,
                                      experiment: experiment,
                                      requestID: activity.requestID)
            }
            experienceRenderer.show(qualifiedExperiences: qualifiedExperienceData, completion: nil)
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
        // this will merge any additional events or profile updates.
        // we do not support any update to the user ID or group ID here, as a change
        // in those values would trigger an immediate flush of pending items then the new update
        // sent. The reason is that the activity prior to that update needs to be associated to
        // the previous user/group and the activity after that update needs to be associated with
        // the new user/group
        if let newEvents = activity.events {
            let existingEvents = events ?? []
            events = existingEvents + newEvents
        }

        // merge in any updated auto props from events or other pending profile updates
        if let newProfileUpdate = activity.profileUpdate {
            let existingProfileUpdate = profileUpdate ?? [:]
            profileUpdate = existingProfileUpdate.merging(newProfileUpdate) { _, new in new }
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
