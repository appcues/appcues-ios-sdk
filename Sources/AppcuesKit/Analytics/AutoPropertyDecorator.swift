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

    // private let storage: Storage
    private let config: Appcues.Config

    private var currentScreen: String?
    private var previousScreen: String?

    // TODO: product reqs on when this resets
    private var sessionPageviews = 0

    // these are the fixed values for the duration of the app runtime
    private var applicationProperties: [String: Any] = [:]

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        configureApplicationProperties()
        container.resolve(AnalyticsPublisher.self).register(decorator: self)
    }

    func decorate(_ tracking: TrackingUpdate) -> TrackingUpdate {

        if case let .screen(title) = tracking.type {
            previousScreen = currentScreen
            currentScreen = title
            sessionPageviews += 1
        }

        var properties = tracking.properties ?? [:]
        var decorated = tracking

        var sessionProperties: [String: Any?] = [
            "userId": tracking.userID,
            "_sessionPageviews": sessionPageviews,
            "_currentPageTitle": currentScreen,
            "_lastPageTitle": previousScreen
        ]

        if !Locale.preferredLanguages.isEmpty {
            sessionProperties["_lastBrowserLanguage"] = Locale.preferredLanguages[0]
        }

        let merged = applicationProperties.merging(sessionProperties.compactMapValues { $0 }) { _, new in new }

        properties["_identity"] = merged
        decorated.properties = properties

        return decorated
    }

    private func configureApplicationProperties() {
        applicationProperties = [
            "_appcuesId": config.accountID,
            "_appId": "{GUID-TBD}",
            "_platform": "ios",
            "_bundlePackageId": Bundle.main.identifier,
            "_appName": Bundle.main.displayName,
            "_appVersion": Bundle.main.version,
            "_appBuild": Bundle.main.build,
            "_sdkVersion": __appcues_version,
            "_sdkName": "appcues-ios"
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
