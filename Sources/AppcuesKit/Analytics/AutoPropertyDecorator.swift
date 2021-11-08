//
//  AutoPropertyDecorator.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/1/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import WebKit

internal class AutoPropertyDecorator: TrackingDecorator {

    private var currentScreen: String?
    private var previousScreen: String?

    // TODO: product reqs on when this resets
    private var sessionPageviews = 0
    private var sessionRandomizer: Int

    private let storage: Storage

    // these are the fixed values for the duration of the app runtime
    private var applicationProperties: [String: Any] = [:]

    init(container: DIContainer) {
        self.sessionRandomizer = Int.random(in: 1...100)
        self.storage = container.resolve(Storage.self)
        configureApplicationProperties()
        container.resolve(AnalyticsPublisher.self).register(decorator: self)
    }

    func decorate(_ tracking: TrackingUpdate) -> TrackingUpdate {

        var isProfileUpdate = false

        switch tracking.type {
        case let .screen(title):
            previousScreen = currentScreen
            currentScreen = title
            sessionPageviews += 1

        case let .event(name):
            if name == "appcues:flow_started" {
                storage.lastContentShownAt = tracking.timestamp
            }

        case .profile:
            isProfileUpdate = true
        }

        var properties = tracking.properties ?? [:]
        var decorated = tracking

        var sessionProperties: [String: Any?] = [
            "userId": tracking.userID,
            "_isAnonymous": storage.isAnonymous,
            "_localId": storage.deviceID,
            "_sessionPageviews": sessionPageviews,
            "_sessionRandomizer": sessionRandomizer,
            "_currentPageTitle": currentScreen,
            "_lastPageTitle": previousScreen,
            "_updatedAt": Date(),
            "_lastContentShownAt": storage.lastContentShownAt
        ]

        if !Locale.preferredLanguages.isEmpty {
            sessionProperties["_lastBrowserLanguage"] = Locale.preferredLanguages[0]
        }

        let merged = applicationProperties.merging(sessionProperties.compactMapValues { $0 }) { _, new in new }

        if isProfileUpdate {
            // profile updates have auto props merged in at root level
            properties = properties.merging(merged) { _, new in new }
        } else {
            // events have auto props nested inside an _identity object
            properties["_identity"] = merged
        }

        decorated.properties = properties

        return decorated
    }

    private func configureApplicationProperties() {
        applicationProperties = [
            "_appId": "{GUID-TBD}",
            "_operatingSystem": "ios",
            "_bundlePackageId": Bundle.main.identifier,
            "_appName": Bundle.main.displayName,
            "_appVersion": Bundle.main.version,
            "_appBuild": Bundle.main.build,
            "_sdkVersion": __appcues_version,
            "_sdkName": "appcues-ios",
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

private extension UIUserInterfaceIdiom {
    var analyticsName: String {
        if self == .pad {
            return "tablet"
        }
        return "phone"
    }
}

private extension UIDevice {
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
