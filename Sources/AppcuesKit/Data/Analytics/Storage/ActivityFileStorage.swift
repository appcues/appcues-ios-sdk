//
//  ActivityFileStorage.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/31/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal protocol ActivityStoring {
    func save(_ activity: ActivityStorage)
    func remove(_ activity: ActivityStorage)
    func read() -> [ActivityStorage]
}

internal class ActivityFileStorage: ActivityStoring {

    private let config: Appcues.Config
    private let decoder = JSONDecoder()

    // the list of UUIDs for Activity requests that are "current" - meaning they are actively being
    // sent as first time requests - not fail/retry items that should be sent again...yet
    //
    // keep this list so they can be ignored when gathering up the stored files to attempt a retry with
    private var processingItems: Set<String> = []

    private var storageDirectory: URL {
        let appcuesURL = FileManager.default.documentsDirectory.appendingPathComponent("appcues/activity/\(config.applicationID)/")
        // try to create it, will fail if already exists - can ignore
        try? FileManager.default.createDirectory(at: appcuesURL, withIntermediateDirectories: true, attributes: nil)
        return appcuesURL
    }

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
    }

    func save(_ activity: ActivityStorage) {
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

    func remove(_ activity: ActivityStorage) {
        let file = storageDirectory.appendingPathComponent(activity.requestID)
        try? FileManager.default.removeItem(atPath: file.path)
    }

    func read() -> [ActivityStorage] {
        let files = (try? FileManager
            .default.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [], options: .skipsHiddenFiles)) ?? []

        let activities: [ActivityStorage] = files.compactMap {
            if let jsonData = (try? String(contentsOf: $0, encoding: .utf8))?.data(using: .utf8) {
               return try? decoder.decode(ActivityStorage.self, from: jsonData)
            }
            return nil
        }

        return activities
    }
}

private extension FileManager {
    var documentsDirectory: URL {
        let paths = urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
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
