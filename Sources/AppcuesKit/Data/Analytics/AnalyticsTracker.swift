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

    private weak var appcues: Appcues?

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

    // this is the background analytics processing queue - 10 sec batch
    private var backgroundActivity: [Activity] = []
    // this is the immediate processing queue - 50ms batch to group identify with immediate subsequent updates
    private var priorityActivity: [Activity] = []

    // holds the work item for background analytics (flow events) to batch and send in 10 sec intervals
    private var backgroundFlushWorkItem: DispatchWorkItem?

    // holds items to be immediately processed, but allowed to group with very near additional updates (50ms)
    private var priorityFlushWorkItem: DispatchWorkItem?

    init(container: DIContainer) {
        self.appcues = container.owner
        self.storage = container.resolve(DataStoring.self)
        self.config = container.resolve(Appcues.Config.self)
        self.activityProcessor = container.resolve(ActivityProcessing.self)
        self.container = container
    }

    func track(update: TrackingUpdate) {
        // session_id is required for activity tracked to API, and it should always be non-nil by
        // this point, as the AnalyticsPublisher will not even invoke it's subscribers unless a
        // valid session exists - see decorateAndPublish in AnalyticsPublisher
        guard let sessionID = appcues?.sessionID else { return }

        let activity = Activity(from: update, config: config, storage: storage, sessionID: sessionID)

        switch update.policy {
        // used by normal interactive screen/track calls
        case .queueThenFlush:
            syncQueue.sync {
                backgroundFlushWorkItem?.cancel()
                backgroundActivity.append(activity)
                flushBackgroundActivity(trackedAt: update.timestamp) // immediately flush, eligible for qualification, so track timing
            }

        // used by identify, group and session_started event
        case .flushThenSend(let waitForBatch):
            syncQueue.sync {
                backgroundFlushWorkItem?.cancel()
                // no timing tracking on pending background activity
                flushBackgroundActivity()
                // immediately flush, eligible for qualification, so track timing
                sendWithPriorityQueue(activity, startQueue: waitForBatch, trackedAt: update.timestamp)
            }

        // used by non-interactive tracking - flow events
        case .queue:
            syncQueue.sync {
                backgroundActivity.append(activity)
                if backgroundFlushWorkItem == nil {
                    let workItem = DispatchWorkItem { [weak self] in
                        self?.syncQueue.sync {
                            self?.flushBackgroundActivity() // no timing tracking on background activity flush
                        }
                    }
                    backgroundFlushWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + config.flushAfterDuration, execute: workItem)
                }
            }
        }
    }

    // to be called when any pending activity should immediately be flushed to cache, and network if possible
    // i.e. app going to background / being killed
    func flush() {
        syncQueue.sync {
            // this will move into priority queue, if exists
            flushBackgroundActivity()
            // flush priority queue, if exists
            flushPriorityActivity()
        }
    }

    // send anything in the background analytics queue, merging into a priority queue, if exists
    private func flushBackgroundActivity(trackedAt: Date? = nil) {
        backgroundFlushWorkItem = nil
        let merged = backgroundActivity.merge()
        backgroundActivity = []
        // sending through the priority queue here - if there
        // is anything batching at 50ms delay (i.e. a new identify)
        // then these items will get merged in. Typically, this
        // is not the case, and they will be sent immediately.
        // `startQueue` is false, as this call will never start a new
        // 50ms delay, only merge with an existing one, if exists.
        sendWithPriorityQueue(merged, startQueue: false, trackedAt: trackedAt)
    }

    // send the priority queue
    private func flushPriorityActivity(trackedAt: Date? = nil) {
        priorityFlushWorkItem = nil
        let merged = priorityActivity.merge()
        priorityActivity = []
        send(merged, trackedAt: trackedAt)
    }

    // initiate the send of this item through the optional priority queue
    // the `startQueue` param will indicate whether a 50ms buffer should be created to allow for
    // calls in very near succession to this one to be batched together.
    //
    // * will only start the queue if `startQueue` is true - this is only used for identify() or
    //   session_started events
    // * if no queue exists, and not starting a queue - will send immediately with no delay
    // * if a queue exists and it contains items from a different user - will flush those existing items
    //   immediately, then process this item
    // * otherwise, add this item to the queue and start it (if not already)
    private func sendWithPriorityQueue(_ activity: Activity?, startQueue: Bool, trackedAt: Date?) {
        guard let activity = activity else { return }
        // if there is no queue in flight, just send it immediate - hopefully common case
        if !startQueue && priorityActivity.isEmpty {
            send(activity, trackedAt: trackedAt)
            return
        }
        // if the queue items are for a different user
        if (priorityActivity.contains(where: { $0.userID != activity.userID })) {
            // flush immediately...
            priorityFlushWorkItem = nil
            flushPriorityActivity()
            // note: we know that background items were already flushed before getting here
            // with a new user identified, in flushThenSend.
            //
            // then try again..
            sendWithPriorityQueue(activity, startQueue: startQueue, trackedAt: trackedAt)
            return
        }
        // add activity to priority queue
        priorityActivity.append(activity)
        // schedule the flush task (if not already)
        if priorityFlushWorkItem == nil {
            let workItem = DispatchWorkItem { [weak self] in
                self?.syncQueue.sync {
                    self?.flushPriorityActivity(trackedAt: trackedAt)
                }
            }
            priorityFlushWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: workItem)
        }
    }

    // final step after all queueing - make the network call to send the activity, and process the result
    private func send(_ activity: Activity?, trackedAt: Date?) {
        guard let activity = activity else { return }
        // `trackedAt` value is only sent in cases of immediate qualification-eligible tracking, for SDK metrics
        SdkMetrics.tracked(activity.requestID, time: trackedAt)
        activityProcessor.process(activity) { [weak self] result in
            switch result {
            case .success(let qualifyResponse):
                if #available(iOS 13.0, *) {
                    let experienceRenderer = self?.container?.resolve(ExperienceRendering.self)
                    experienceRenderer?.processAndShow(
                        qualifiedExperiences: self?.process(qualifyResponse: qualifyResponse, activity: activity) ?? [],
                        reason: .qualification(reason: qualifyResponse.qualificationReason)
                    )

                    if qualifyResponse.experiences.isEmpty {
                        // common case, nothing qualified - we know there was nothing to render, so just remove tracking
                        SdkMetrics.remove(activity.requestID)
                    }
                } else {
                    self?.config.logger.info("iOS 13 or above is required to render an Appcues experience")
                    // nothing will render, we can remove tracking
                    SdkMetrics.remove(activity.requestID)
                }
            case .failure(let error):
                self?.config.logger.error("Failed processing qualify response: %{public}@", "\(error)")
                SdkMetrics.remove(activity.requestID)
            }
        }
    }

    @available(iOS 13.0, *)
    private func process(qualifyResponse: QualifyResponse, activity: Activity) -> [ExperienceData] {
        let experiments = qualifyResponse.experiments ?? []
        return qualifyResponse.experiences.map { item in
            let (experience, error) = item.parsed
            let experiment = experiments.first { $0.experienceID == experience.id }
            return ExperienceData(
                experience,
                trigger: .qualification(reason: qualifyResponse.qualificationReason),
                priority: qualifyResponse.renderPriority,
                published: true,
                experiment: experiment,
                requestID: activity.requestID,
                error: error
            )
        }
    }
}

extension Activity {
    init(from update: TrackingUpdate, config: Appcues.Config, storage: DataStoring, sessionID: UUID) {
        switch update.type {
        case let .event(name, _):
            self.init(
                accountID: config.accountID,
                sessionID: sessionID.appcuesFormatted,
                userID: storage.userID,
                events: [Event(name: name, attributes: update.properties, context: update.context, logger: config.logger)],
                profileUpdate: update.eventAutoProperties,
                groupID: storage.groupID,
                userSignature: storage.userSignature,
                logger: config.logger
            )
        case let .screen(title):
            self.init(
                accountID: config.accountID,
                sessionID: sessionID.appcuesFormatted,
                userID: storage.userID,
                events: [Event(screen: title, attributes: update.properties, context: update.context, logger: config.logger)],
                profileUpdate: update.eventAutoProperties,
                groupID: storage.groupID,
                userSignature: storage.userSignature,
                logger: config.logger
            )
        case .profile:
            self.init(
                accountID: config.accountID,
                sessionID: sessionID.appcuesFormatted,
                userID: storage.userID,
                events: nil,
                profileUpdate: update.properties,
                groupID: storage.groupID,
                userSignature: storage.userSignature,
                logger: config.logger
            )
        case .group:
            self.init(
                accountID: config.accountID,
                sessionID: sessionID.appcuesFormatted,
                userID: storage.userID,
                events: nil,
                groupID: storage.groupID,
                groupUpdate: update.properties,
                userSignature: storage.userSignature,
                logger: config.logger
            )
        }
    }

    mutating func append(_ activity: Activity) {
        // this will merge any additional events or profile updates.
        // we do not support any update to the user ID, as a change
        // in that values would trigger an immediate flush of pending items then the new update
        // sent. The reason is that the activity prior to that update needs to be associated to
        // the previous user and the activity after that update needs to be associated with
        // the new user (part of the API path and root of request)
        if let newEvents = activity.events {
            let existingEvents = events ?? []
            events = existingEvents + newEvents
        }

        // merge in any updated auto props from events or other pending profile updates
        if let newProfileUpdate = activity.profileUpdate {
            let existingProfileUpdate = profileUpdate ?? [:]
            profileUpdate = existingProfileUpdate.merging(newProfileUpdate)
        }

        // merge in any updated group info
        groupID = activity.groupID
        if let newGroupUpdate = activity.groupUpdate {
            let existingGroupUpdate = groupUpdate ?? [:]
            groupUpdate = existingGroupUpdate.merging(newGroupUpdate)
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
