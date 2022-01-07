//
//  ActivityProcessor.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/3/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal protocol ActivityProcessing {
    func process(_ activity: Activity, sync: Bool, completion: ((Result<Taco, Error>) -> Void)?)
    func flush()
}

/// This class is responsible for the network transport of analytics data to the /activity API endpoint.  This includes
/// the underlying persistent cache and retry, if necessary, for connection issues or app termination - to avoid loss of data.
internal class ActivityProcessor: ActivityProcessing {

    // container for client side cache files that allow simple access to the
    // data necessary for a later retry if anything failed on initial send
    private struct ActivityCache: Codable {
        let accountID: String
        let userID: String
        let requestID: String
        let data: Data
        let created: Date

        // could have a more advanced policy for things like only attempting after x seconds
        var lastAttempt: Date?
        // or only attempting a max X times then clearing from cache
        var numberOfAttempts = 0

        init?(_ activity: Activity) {
            guard let data = try? NetworkClient.encoder.encode(activity) else {
                return nil
            }
            self.accountID = activity.accountID
            self.userID = activity.userID
            self.requestID = activity.requestID.uuidString
            self.data = data
            self.created = Date()
        }
    }

    private let config: Appcues.Config
    private let networking: Networking
    private let decoder = JSONDecoder()

    // the list of UUIDs for Activity requests that are "current" - meaning they are actively being
    // sent as first time requests - not fail/retry items that should be sent again...yet
    //
    // keep this list so they can be ignored when gathering up the cache files to attempt a retry with
    private var processingItems: Set<String> = []

    private var storageDirectory: URL {
        let appcuesURL = FileManager.default.documentsDirectory.appendingPathComponent("appcues/activity/\(config.applicationID)/")
        // try to create it, will fail if already exists - can ignore
        try? FileManager.default.createDirectory(at: appcuesURL, withIntermediateDirectories: true, attributes: nil)
        return appcuesURL
    }

    private var getPendingFiles: [URL] {
        let allFiles = try? FileManager
            .default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
        // exclude any items that are currently in flight / first time requests
        return allFiles?.filter { !processingItems.contains($0.lastPathComponent) } ?? []
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.networking = container.resolve(Networking.self)
    }

    func process(_ activity: Activity, sync: Bool, completion: ((Result<Taco, Error>) -> Void)?) {
        guard let cache = ActivityCache(activity) else { return }

        // store this item to a file - so we can retry later should anything go wrong, app killed, etc
        store(cache)

        // then flush the cache, including this current item and perhaps anything else that needs retry
        flush(cache: cache, sync: sync, completion: completion)
    }

    // supports clearing out any pending cache from elsewhere - session start?
    func flush() {
        flush(cache: nil, sync: false, completion: nil)
    }

    private func flush(cache: ActivityCache?, sync: Bool, completion: ((Result<Taco, Error>) -> Void)?) {
        // now gather up all the pending files in cache (might be more failed items before this one)
        // and sort them by create date
        let activities: [ActivityCache] = getPendingFiles.compactMap {
            if let jsonData = try? String(contentsOf: $0, encoding: .utf8).data(using: .utf8) {
               return try? decoder.decode(ActivityCache.self, from: jsonData)
            }
            return nil
        }

        let itemsToFlush = prepareCache(available: activities)

        // mark them all as requests in process
        processingItems.formUnion(itemsToFlush.map { $0.requestID })

        post(activities: itemsToFlush, currentRequestID: cache?.requestID, currentSync: sync, currentCompletion: completion)
    }

    // this method returns the X (based on config) applicable items to flush from the cache.
    // there may be a bunch of other older things lingering around in the cache filesystem, but
    // we are not supporting a full offline mode capability at this time - i.e. we'll not flush out
    // 1,000+ collected items or let things linger indefinitely - the purpose of our cache is simply
    // a relatively near-term error/retry mechanism for intermittent network instability
    private func prepareCache(available: [ActivityCache]) -> [ActivityCache] {
        let activities = available.sorted { $0.created < $1.created }
        let count = activities.count

        // only flush max X, based on config
        let cacheSize = Int(config.activityCacheSize)
        // since items are sorted chronologically, we take the most recent from the end (suffix)
        let mostRecent = Array(activities.suffix(cacheSize))
        var outdated: [ActivityCache] = []

        // if there are more items in the cache than allowed, trim off the front, up to our allowed
        // cache size, and mark them as outdated (for deletion)
        if count > config.activityCacheSize {
            outdated.append(contentsOf: activities.prefix(upTo: count - cacheSize))
        }

        // optionally, if a max age is specified, filter out items that are older
        var eligible: [ActivityCache]
        if let maxAgeSeconds = config.activityCacheMaxAge {
            // need to filter out those older than the max age
            eligible = []
            for activity in mostRecent {
                let elapsed = Int(Date().timeIntervalSince(activity.created))
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
            remove(oldItem)
        }

        return eligible
    }

    private func post(activities: [ActivityCache],
                      currentRequestID: String?,
                      currentSync: Bool,
                      currentCompletion: ((Result<Taco, Error>) -> Void)?) {
        var activities = activities
        guard !activities.isEmpty else { return } // done - nothing in the queue

        let activity = activities.removeFirst()

        // check if this item in the list is the "current" activity that triggered this processing initially
        let isCurrent = activity.requestID == currentRequestID

        // if so, make sure its completion gets passed along.  any other retry attempts will not have completion blocks
        let completion = isCurrent ? currentCompletion : nil

        // similarly, pass along the `sync` value (synchronous qualification flag) for the current activity
        let sync = isCurrent ? currentSync : false

        networking.post(
            to: APIEndpoint.activity(userID: activity.userID, sync: sync),
            body: activity.data
        ) { [weak self] (result: Result<Taco, Error>) in

            guard let self = self else { return }

            var success = true
            if case let .failure(error) = result, error.requiresRetry {
                success = false
            }

            // if it was successful (or retry not enabled), no retry needed - clean out the file
            if success {
                self.remove(activity)
            }

            // then, always remove it from the list of current items "in flight" - this allows
            // a later retry to run, if it was needed
            self.processingItems.remove(activity.requestID)

            completion?(result)

            // recurse on remainder of the queue
            self.post(activities: activities,
                      currentRequestID: currentRequestID,
                      currentSync: currentSync,
                      currentCompletion: currentCompletion)
        }
    }

    private func remove(_ activity: ActivityCache) {
        let file = storageDirectory.appendingPathComponent(activity.requestID)
        try? FileManager.default.removeItem(atPath: file.path)
    }

    private func store(_ activity: ActivityCache) {
        var activity = activity
        activity.lastAttempt = Date()
        activity.numberOfAttempts += 1

        let jsonString = activity.toString()
        if let jsonData = jsonString.data(using: .utf8) {
            let file = storageDirectory.appendingPathComponent(activity.requestID)
            // will replace if exists (shouldnt)
            FileManager.default.createFile(atPath: file.path, contents: jsonData)
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
            // and we should clear the item out of cache and not retry.  This avoid continously sending
            // something that the server is rejecting as malformed, for example.
            // in the future, we may retry on some types of server errors, but out of scope currently.
            return false
        }
    }
}

private extension Encodable {
    func prettyPrint() -> String {
        return toString(pretty: true)
    }

    func toString() -> String {
        return toString(pretty: false)
    }

    func toString(pretty: Bool) -> String {
        var returnString = ""
        do {
            let encoder = JSONEncoder()
            if pretty {
                encoder.outputFormatting = .prettyPrinted
            }

            let json = try encoder.encode(self)
            if let printed = String(data: json, encoding: .utf8) {
                returnString = printed
            }
        } catch {
            returnString = error.localizedDescription
        }
        return returnString
    }
}

private extension FileManager {
    var documentsDirectory: URL {
        let paths = urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
