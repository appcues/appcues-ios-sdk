//
//  AutoPropertyDecorator.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/1/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import WebKit

internal class AutoPropertyDecorator: AnalyticsDecorating {

    private var currentScreen: String?
    private var previousScreen: String?
    private var sessionPageviews = 0
    private var sessionRandomizer: Int?
    private var sessionLatestUserProperties: [String: Any] = [:]

    private weak var appcues: Appcues?
    private let storage: DataStoring
    private let pushMonitor: PushMonitoring
    private let config: Appcues.Config

    // these are the fixed values for the duration of the app runtime
    private lazy var applicationProperties: [String: Any] = {
        [
            "_appId": config.applicationID,
            "_operatingSystem": "iOS",
            "_bundlePackageId": Bundle.main.identifier,
            "_appName": Bundle.main.displayName,
            "_appVersion": Bundle.main.version,
            "_appBuild": Bundle.main.build,
            "_sdkVersion": __appcues_version,
            "_sdkName": "appcues-ios",
            "_osVersion": UIDevice.current.systemVersion,
            "_deviceType": UIDevice.current.userInterfaceIdiom.analyticsName,
            "_deviceModel": UIDevice.current.modelName,
            "_timezoneOffset": TimeZone.current.minutesFromGMT(),
            "_timezoneCode": TimeZone.current.identifier
        ]
    }()

    var deviceLanguage: String? { Bundle.main.preferredLocalizations.first }

    // these may be redundant with _identity auto props in some cases, but backend
    // systems requested that we send in both spots on requests
    private lazy var contextProperties: [String: Any] = [
        "app_id": config.applicationID,
        "app_version": Bundle.main.version
    ]

    init(container: DIContainer) {
        self.appcues = container.owner
        self.storage = container.resolve(DataStoring.self)
        self.pushMonitor = container.resolve(PushMonitoring.self)
        self.config = container.resolve(Appcues.Config.self)
    }

    func decorate(_ tracking: TrackingUpdate) -> TrackingUpdate {
        // Early return for group updates
        if case let .group(id) = tracking.type {
            if id == nil {
                // removing from a group should not have any auto props
                return tracking
            } else {
                // group updates only have this single auto prop, so add that and return early
                var decorated = tracking
                decorated.properties = (decorated.properties ?? [:]).merging(["_lastSeenAt": Date()])
                return decorated
            }
        }

        var context = self.contextProperties
        var decorated = tracking

        // Update values
        switch tracking.type {
        case let .screen(title):
            previousScreen = currentScreen
            currentScreen = title
            sessionPageviews += 1
            context["screen_title"] = title
        case .event(Events.Session.sessionStarted.rawValue, _):
            sessionPageviews = 0
            sessionRandomizer = Int.random(in: 1...100)
            sessionLatestUserProperties = [:]
            currentScreen = nil
            previousScreen = nil
        default:
            break
        }

        let now = Date()

        let sessionProperties: [String: Any?] = [
            "userId": storage.userID,
            "_isAnonymous": storage.isAnonymous,
            "_localId": storage.deviceID,
            "_sessionPageviews": sessionPageviews,
            "_sessionRandomizer": sessionRandomizer,
            "_currentScreenTitle": currentScreen,
            "_lastScreenTitle": previousScreen,
            "_lastBrowserLanguage": deviceLanguage,
            // _lastSeenAt deprecates _updatedAt which can't be entirely removed since it's used for targeting
            "_lastSeenAt": now,
            "_updatedAt": now,
            "_lastContentShownAt": storage.lastContentShownAt,
            "_sessionId": appcues?.sessionID?.appcuesFormatted,
            "_pushPrimerEligible": pushMonitor.pushPrimerEligible
        ]

        // Note: additional (custom) go first, as they may be overwritten by merged system items
        let merged = config.additionalAutoProperties
            .merging(sessionLatestUserProperties)
            .merging(applicationProperties)
            .merging(sessionProperties.compactMapValues { $0 })

        if case .profile = tracking.type {
            // profile updates have auto props merged in at root level
            decorated.properties = (tracking.properties ?? [:]).merging(merged)

            // any profile properties are saved to be added to attributes._identity on all subsequent events
            sessionLatestUserProperties = tracking.properties?.compactMapValues { $0 } ?? [:]
        } else {
            // all other events have auto props within attributes._identity
            decorated.identityAutoProperties = merged
        }

        switch tracking.type {
        case .event(Events.Session.sessionStarted.rawValue, _),
                .event(Events.Device.deviceUpdated.rawValue, _),
                .event(Events.Device.deviceUnregistered.rawValue, _):
            decorated.deviceAutoProperties = deviceAutoProperties().merging(applicationProperties)
        default:
            break
        }

        decorated.context = context

        return decorated
    }

    private func deviceAutoProperties() -> [String: Any] {
        // Explicitly encode null value
        let pushToken: Any = storage.pushToken ?? NSNull()

        var properties = [
            "_deviceId": storage.deviceID,
            "_pushToken": pushToken,
            "_pushEnabled": pushMonitor.pushEnabled,
            "_pushEnabledBackground": pushMonitor.pushBackgroundEnabled
        ]

        if let environment = pushMonitor.pushEnvironment.environmentValue {
            properties["_pushEnvironment"] = environment
        }

        if let language = deviceLanguage {
            properties["_language"] = language
        }

        return properties
    }
}

extension UIUserInterfaceIdiom {
    var analyticsName: String {
        if self == .pad {
            return "tablet"
        }
        return "phone"
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier += String(UnicodeScalar(UInt8(value)))
        }
    }
}

extension TimeZone {
    func minutesFromGMT() -> Int {
        TimeZone.current.secondsFromGMT() / 60
    }
}

extension TrackingUpdate {
    // events have auto props nested inside an _identity object
    var identityAutoProperties: [String: Any]? {
        get {
            return properties?["_identity"] as? [String: Any]
        }
        set {
            var newProps = properties ?? [:]
            newProps["_identity"] = newValue
            properties = newProps
        }
    }

    // some events have device-related auto props nested inside a _device object
    var deviceAutoProperties: [String: Any]? {
        get {
            return properties?["_device"] as? [String: Any]
        }
        set {
            var newProps = properties ?? [:]
            newProps["_device"] = newValue
            properties = newProps
        }
    }

}
