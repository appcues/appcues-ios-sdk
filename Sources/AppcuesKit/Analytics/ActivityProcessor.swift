//
//  ActivityProcessor.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/3/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// This class is responsible for the network transport of analytics data to the /activity API endpoint.  This includes
/// the underlying persistent cache and retry, if necessary, for connection issues or app termination - to avoid loss of data.
internal class ActivityProcessor {

    // container for client side cache files that allow simple access to the
    // data necessary for a later retry if anything failed on initial send
    private struct ActivityCache: Codable {
        let accountID: String
        let userID: String
        let requestID: String
        let data: Data

        // could have a more advanced policy for things like only attempting after x seconds
        var lastAttempt = Date()
        // or only attempting a max X times then clearing from cache
        var numberOfAttempts = 0

        init?(_ activity: Activity) {
            guard let data = try? Networking.encoder.encode(activity) else {
                return nil
            }
            self.accountID = activity.accountID
            self.userID = activity.userID
            self.requestID = activity.requestID.uuidString
            self.data = data
        }

        mutating func saveAttempt(in directory: URL) {
            lastAttempt = Date()
            numberOfAttempts += 1

            let jsonString = self.toString()
            if let jsonData = jsonString.data(using: .utf8) {
                let file = directory.appendingPathComponent(requestID)
                // will replace if exists (shouldnt)
                FileManager.default.createFile(atPath: file.path, contents: jsonData)
            }
        }

        func remove(from directory: URL) {
            do {
                let file = directory.appendingPathComponent(requestID)
                try FileManager.default.removeItem(atPath: file.path)
            } catch {
                print("Failed to remove: \(error)")
            }
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

    // only allow a single retry attempt from cache files at a time
    private var isProcessingRetry = false

    private var storageDirectory: URL {
        let appcuesURL = FileManager.default.documentsDirectory.appendingPathComponent("appcues/activity/\(config.applicationID)/")
        // try to create it, will fail if already exists - can ignore
        try? FileManager.default.createDirectory(at: appcuesURL, withIntermediateDirectories: true, attributes: nil)
        return appcuesURL
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.networking = container.resolve(Networking.self)
    }

    func process(_ activity: Activity?, sync: Bool, completion: ((Result<Taco, Error>) -> Void)?) {
        guard let activity = activity,
              var cache = ActivityCache(activity) else {
                  return
              }

        // first, add to list of items in process - so a background retry does not include this
        processingItems.insert(cache.requestID)

        // second, store this item to a file - so we can retry later should anything go wrong, app killed, etc
        cache.saveAttempt(in: storageDirectory)

        // third, try to POST out to the network
        post(activity: cache, sync: sync, isRetry: false, completion: completion)
    }

    private func post(activity: ActivityCache, sync: Bool, isRetry: Bool, completion: ((Result<Taco, Error>) -> Void)? = nil) {
        networking.post(
            to: Networking.APIEndpoint.activity(userID: activity.userID, sync: sync),
            body: activity.data
        ) { [weak self] (result: Result<Taco, Error>) in

            switch result {
            case .success:
                self?.completeProcessing(activity: activity, success: true, isRetry: isRetry)

            case .failure(let error):

                // we only want to keep in the queue for retry if it was a client side issue with connection
                // are there other error cases we should consider here beyond NSURLErrorNotConnectedToInternet?
                // https://developer.apple.com/documentation/foundation/urlerror/2293104-notconnectedtointernet
                // some for example:
                // timedOut, cannotFindHost, dataNotAllowed, dnsLookupFailed, networkConnectionLost, ...
                let success: Bool
                switch error {
                case URLError.notConnectedToInternet:
                    success = false
                default:
                    // all other responses are considered a successful request, in terms of client behavior
                    // and we should clear the item out of cache and not retry.  This avoid continously sending
                    // something that the server is rejecting as malformed, for example.
                    //success = true
                    success = false // TESTING
                }

                // in the future, we may retry on some types of server errors, but out of scope currently.
                self?.completeProcessing(activity: activity, success: success, isRetry: isRetry)
            }

            completion?(result)
        }
    }

    // depending on success/fail - clean up cache and processing state
    private func completeProcessing(activity: ActivityCache, success: Bool, isRetry: Bool) {
        // if it was successful, no retry needed - clean out the file
        if success {
            activity.remove(from: storageDirectory)
        }

        // then, always remove it from the list of current items "in flight" - this allows
        // a later retry to run, if it was needed
        processingItems.remove(activity.requestID)

        // do not want to trigger another retry pass from within a retry, `isRetry` guards against that
        if !isRetry, success {
            retryIfNeeded()
        }
    }

    private func retryIfNeeded() {
        // TODO: any way to avoid hitting filesystem query each time here? is that an issue?
        let files = getFilesForRetry()
        files.forEach {
            if let jsonData = try? String(contentsOf: $0, encoding: .utf8).data(using: .utf8),
               var activity = try? decoder.decode(ActivityCache.self, from: jsonData) {

                processingItems.insert(activity.requestID)
                activity.saveAttempt(in: storageDirectory)

                // the completion of POST will clean it out of cache, if successful
                post(activity: activity, sync: false, isRetry: true)
            }
        }
    }

    private func getFilesForRetry() -> [URL] {
        let allFiles = try? FileManager
            .default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
        // exclude any items that are currently in flight / first time requests
        return allFiles?.filter { !processingItems.contains($0.lastPathComponent) } ?? []
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
