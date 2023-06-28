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
    private let config: Appcues.Config

    // these are the fixed values for the duration of the app runtime
    private var applicationProperties: [String: Any] = [:]

    // these may be redundant with _identity auto props in some cases, but backend
    // systems requested that we send in both spots on requests
    private lazy var contextProperties: [String: Any] = [
        "app_id": config.applicationID,
        "app_version": Bundle.main.version
    ]

    init(container: DIContainer) {
        self.appcues = container.owner
        self.storage = container.resolve(DataStoring.self)
        self.config = container.resolve(Appcues.Config.self)
        configureApplicationProperties()
    }

    func decorate(_ tracking: TrackingUpdate) -> TrackingUpdate {

        var context = self.contextProperties

        switch tracking.type {
        case let .screen(title):
            previousScreen = currentScreen
            currentScreen = title
            sessionPageviews += 1
            context["screen_title"] = title
        case .event(SessionEvents.sessionStarted.rawValue, _):
            sessionPageviews = 0
            sessionRandomizer = Int.random(in: 1...100)
            sessionLatestUserProperties = [:]
            currentScreen = nil
            previousScreen = nil
        case .group:
            // group updates do not have auto props, don't manipulate anything in the properties
            return tracking
        default:
            break
        }

        var decorated = tracking

        let sessionProperties: [String: Any?] = [
            "userId": storage.userID,
            "_isAnonymous": storage.isAnonymous,
            "_localId": storage.deviceID,
            "_sessionPageviews": sessionPageviews,
            "_sessionRandomizer": sessionRandomizer,
            "_currentScreenTitle": currentScreen,
            "_lastScreenTitle": previousScreen,
            "_updatedAt": Date(),
            "_lastContentShownAt": storage.lastContentShownAt,
            "_sessionId": appcues?.sessionID?.appcuesFormatted,
            "_lastBrowserLanguage": Locale.current.languageCode
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
            decorated.eventAutoProperties = merged
        }

        decorated.context = context

        return decorated
    }

    private func configureApplicationProperties() {
        applicationProperties = [
            "_appId": config.applicationID,
            "_operatingSystem": "ios",
            "_bundlePackageId": Bundle.main.identifier,
            "_appName": Bundle.main.displayName,
            "_appVersion": Bundle.main.version,
            "_appBuild": Bundle.main.build,
            "_sdkVersion": __appcues_version,
            "_sdkName": "appcues-ios",
            "_osVersion": UIDevice.current.systemVersion,
            "_deviceType": UIDevice.current.userInterfaceIdiom.analyticsName,
            "_deviceModel": UIDevice.current.modelName
        ]

        if Thread.isMainThread {
            updateUserAgent()
        } else {
            DispatchQueue.main.sync {
                self.updateUserAgent()
            }
        }
    }

    private func updateUserAgent() {
        guard let userAgent = WKWebView().value(forKey: "userAgent") as? String else { return }
        applicationProperties["_userAgent"] = userAgent
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

extension TrackingUpdate {
    // events have auto props nested inside an _identity object
    var eventAutoProperties: [String: Any]? {
        get {
            return properties?["_identity"] as? [String: Any]
        }
        set {
            var newProps = properties ?? [:]
            newProps["_identity"] = newValue
            properties = newProps
        }
    }
}
