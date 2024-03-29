//
//  ActivityProcessor.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/3/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal protocol ActivityProcessing: AnyObject {
    func process(_ activity: Activity, completion: @escaping (Result<QualifyResponse, Error>) -> Void)
}

/// This class is responsible for the network transport of analytics data to the /activity API endpoint. This includes
/// the underlying persistent storage and retry, if necessary, for connection issues or app termination - to avoid loss of data.
internal class ActivityProcessor: ActivityProcessing {

    private let config: Appcues.Config
    private let networking: Networking
    private let activityStorage: ActivityStoring

    // the list of UUIDs for Activity requests that are "current" - meaning they are actively being
    // sent as first time requests - not fail/retry items that should be sent again...yet
    //
    // keep this list so they can be ignored when gathering up the stored files to attempt a retry with
    private var processingItems: Set<UUID> = []

    private let syncQueue = DispatchQueue(label: "appcues-activity-processor")

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.networking = container.resolve(Networking.self)
        self.activityStorage = container.resolve(ActivityStoring.self)
    }

    func process(_ activity: Activity, completion: @escaping (Result<QualifyResponse, Error>) -> Void) {
        guard let activity = ActivityStorage(activity) else { return }

        var itemsToFlush: [ActivityStorage] = []

        syncQueue.sync {
            // mark current item as processing - before saving to storage - so no other activity
            // on other threads could possibly pickup and include
            processingItems.insert(activity.requestID)

            // store this item to a file - so we can retry later should anything go wrong, app killed, etc
            activityStorage.save(activity)

            // get the set of other items in storage that previously failed and need retry
            // exclude any items that are currently in flight already
            let stored = activityStorage.read().filter { !processingItems.contains($0.requestID) }

            itemsToFlush = prepareForRetry(available: stored)

            // add the current item (since it was marked as processing already)
            itemsToFlush.append(activity)

            // mark them all as requests in process
            processingItems.formUnion(itemsToFlush.map { $0.requestID })
        }

        post(activities: itemsToFlush, current: activity, completion: completion)
    }

    // this method returns the X (based on config) applicable items to flush from storage.
    // there may be a bunch of other older things lingering around in storage, but
    // we are not supporting a full offline mode capability at this time - i.e. we'll not flush out
    // 1,000+ collected items or let things linger indefinitely - the purpose of our storage is simply
    // a relatively near-term error/retry mechanism for intermittent network instability
    private func prepareForRetry(available: [ActivityStorage]) -> [ActivityStorage] {
        let activities = available.sorted { $0.created < $1.created }
        let count = activities.count

        // only flush max X, based on config
        let storageMaxSize = Int(config.activityStorageMaxSize)
        // since items are sorted chronologically, we take the most recent from the end (suffix)
        let mostRecent = Array(activities.suffix(storageMaxSize))
        var outdated: [ActivityStorage] = []

        // if there are more items in storage than allowed, trim off the front, up to our allowed
        // storage size, and mark them as outdated (for deletion)
        if count > storageMaxSize {
            outdated.append(contentsOf: activities.prefix(upTo: count - storageMaxSize))
        }

        // optionally, if a max age is specified, filter out items that are older
        var eligible: [ActivityStorage]
        if let configMaxAgeSeconds = config.activityStorageMaxAge {
            // need to filter out those older than the max age
            eligible = []
            let maxAgeSeconds = Double(configMaxAgeSeconds)
            for activity in mostRecent {
                let elapsed = Date().timeIntervalSince(activity.created)
                if elapsed > maxAgeSeconds {
                    // too old
                    outdated.append(activity)
                } else {
                    // good to go
                    eligible.append(activity)
                }
            }

        } else {
            // no max age, so all of most recent, up to max size, can be sent
            eligible = mostRecent
        }

        // remove outdated items from filesystem - no longer valid
        for oldItem in outdated {
            activityStorage.remove(oldItem)
        }

        return eligible
    }

    private func post(
        activities: [ActivityStorage],
        current: ActivityStorage,
        completion: @escaping (Result<QualifyResponse, Error>) -> Void
    ) {
        var activities = activities
        guard !activities.isEmpty else { return } // done - nothing in the queue
        let activity = activities.removeFirst()

        // check if this item in the list is the "current" activity that triggered this processing initially
        if activity.requestID == current.requestID {
            // if so, it is a /qualify request and it is the end of the line for this queue process
            handleQualify(activity: activity, completion: completion)
        } else {
            // otherwise, it is a retry item, use /activity endpoint, and recurse when done
            handleActivity(activity: activity) { [weak self] in
                // recurse on remainder of the queue
                self?.post(activities: activities, current: current, completion: completion)
            }
        }
    }

    private func handleActivity(activity: ActivityStorage, completion: @escaping () -> Void) {
        networking.post(
            to: APIEndpoint.activity(userID: activity.userID),
            authorization: Authorization(bearerToken: activity.userSignature),
            body: activity.data,
            requestId: nil
        ) { [weak self] (result: Result<ActivityResponse, Error>) in
            guard let self = self else { return }
            var success = true
            if case let .failure(error) = result, error.requiresRetry { success = false }
            self.postProcess(activity: activity, success: success)
            completion()
        }
    }

    private func handleQualify(activity: ActivityStorage, completion: @escaping (Result<QualifyResponse, Error>) -> Void) {
        networking.post(
            to: APIEndpoint.qualify(userID: activity.userID),
            authorization: Authorization(bearerToken: activity.userSignature),
            body: activity.data,
            requestId: activity.requestID
        ) { [weak self] (result: Result<QualifyResponse, Error>) in
            guard let self = self else { return }
            var success = true
            if case let .failure(error) = result, error.requiresRetry { success = false }
            self.postProcess(activity: activity, success: success)

            // the current activity sent for qualification is the end of processing, invoke completion
            completion(result)
        }
    }

    private func postProcess(activity: ActivityStorage, success: Bool) {
        syncQueue.sync {
            // if it was successful (or retry not enabled), no retry needed - clean out the file
            if success {
                self.activityStorage.remove(activity)
            }

            // then, always remove it from the list of current items "in flight" - this allows
            // a later retry to run, if it was needed
            self.processingItems.remove(activity.requestID)
        }
    }

}

private extension Error {
    var requiresRetry: Bool {
        // we only want to keep in the queue for retry if it was a client side issue with connection
        // are there other error cases we should consider here beyond those identified in the switch below?
        // https://developer.apple.com/documentation/foundation/urlerror/2293104-notconnectedtointernet
        // some for example:
        // cannotFindHost, dnsLookupFailed, networkConnectionLost, ...
        switch self {
        case URLError.notConnectedToInternet,
            URLError.timedOut,
            URLError.dataNotAllowed,
            URLError.internationalRoamingOff:
            return true
        default:
            // all other responses are considered a successful request, in terms of client behavior
            // and we should clear the item out of storage and not retry. This avoids continuously sending
            // something that the server is rejecting as malformed, for example.
            // in the future, we may retry on some types of server errors, but out of scope currently.
            return false
        }
    }
}
