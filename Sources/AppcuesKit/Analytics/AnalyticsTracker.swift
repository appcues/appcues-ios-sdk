//
//  AnalyticsTracker.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal class AnalyticsTracker {

    enum LifecycleEvents: String {
        case applicationInstalled = "Application Installed"
        case applicationOpened = "Application Opened"
        case applicationUpdated = "Application Updated"
        case applicationBackgrounded = "Application Backgrounded"
    }

    private let container: DIContainer

    private lazy var config = container.resolve(Appcues.Config.self)
    private lazy var storage = container.resolve(Storage.self)
    private lazy var networking = container.resolve(Networking.self)
    private lazy var flowRenderer = container.resolve(FlowRenderer.self)

    private var lastTrackedScreen: String?
    private var wasBackgrounded = false

    var launchType: LaunchType = .open

    init(container: DIContainer) {
        self.container = container

        if config.trackScreens {
            configureScreenTracking()
        }

        if config.trackLifecycle {
            configureLifecycleTracking()
        }

        registerForAnalyticsUpdates(container)
    }

    private func identify(properties: [String: Any]? = nil) {
        let activity = Activity(events: nil, profileUpdate: properties)
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: Networking.APIEndpoint.activity(accountID: config.accountID, userID: storage.userID),
            body: data
        ) { (result: Result<Taco, Error>) in
            print(result)
        }
    }

    private func track(name: String, properties: [String: Any]? = nil) {
        let activity = Activity(events: [Event(name: name, attributes: properties)], profileUpdate: nil)
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        networking.post(
            to: Networking.APIEndpoint.activity(accountID: config.accountID, userID: storage.userID),
            body: data
        ) { (result: Result<Taco, Error>) in
            print(result)
        }
    }

    private func screen(title: String, properties: [String: Any]? = nil) {
        guard let urlString = generatePseudoURL(screenName: title) else {
            config.logger.error("Could not construct url for page %s", title)
            return
        }

        let activity = Activity(events: [Event(pageView: urlString, attributes: properties)])
        guard let data = try? Networking.encoder.encode(activity) else {
            return
        }

        lastTrackedScreen = title

        networking.post(
            to: Networking.APIEndpoint.activity(accountID: config.accountID, userID: storage.userID),
            body: data
        ) { [weak self] (result: Result<Taco, Error>) in
            switch result {
            case .success(let taco):
                // This assumes that the returned flows are ordered by priority.
                if let flow = taco.contents.first {
                    self?.flowRenderer.show(flow: flow)
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    // Temporary solution to piggyback on the web page views. A proper mobile screen solution is still needed.
    private func generatePseudoURL(screenName: String) -> String? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Bundle.main.bundleIdentifier
        components.path = "/" + screenName.asURLSlug
        return components.string
    }

    private func configureScreenTracking() {

        func swizzle(forClass: AnyClass, original: Selector, new: Selector) {
            guard let originalMethod = class_getInstanceMethod(forClass, original) else { return }
            guard let swizzledMethod = class_getInstanceMethod(forClass, new) else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        swizzle(forClass: UIViewController.self,
                original: #selector(UIViewController.viewDidAppear(_:)),
                new: #selector(UIViewController.appcues__viewDidAppear)
        )

        NotificationCenter.default.addObserver(self, selector: #selector(screenTracked), name: .appcuesTrackedScreen, object: nil)
    }

    @objc
    private func screenTracked(notification: Notification) {
        let name: String? = notification.value()
        guard let name = name, lastTrackedScreen != name else { return }
        screen(title: name)
    }

    private func configureLifecycleTracking() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didFinishLaunching),
                                               name: UIApplication.didFinishLaunchingNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc
    func didFinishLaunching(notification: Notification) {
        let launchOptions = notification.userInfo as? [UIApplication.LaunchOptionsKey: Any]
        track(name: launchType.lifecycleEvent.rawValue, properties: [
            "from_background": false,
            "referring_application": launchOptions?[UIApplication.LaunchOptionsKey.sourceApplication] ?? "",
            "url": launchOptions?[UIApplication.LaunchOptionsKey.url] ?? ""
        ])
    }

    @objc
    func applicationWillEnterForeground(notification: Notification) {
        guard wasBackgrounded else { return }
        wasBackgrounded = false
        track(name: LifecycleEvents.applicationOpened.rawValue,
              properties: [
                "from_background": true
              ])
    }

    @objc
    func didEnterBackground(notification: Notification) {
        wasBackgrounded = true
        track(name: LifecycleEvents.applicationBackgrounded.rawValue)
    }
}

extension AnalyticsTracker: AnalyticsSubscriber {
    func track(update: TrackingUpdate) {
        switch update.type {
        case let .event(name):
            track(name: name, properties: update.properties)

        case let .screen(title):
            screen(title: title, properties: update.properties)

        case .profile:
            identify(properties: update.properties)
        }
    }
}

private extension LaunchType {
    var lifecycleEvent: AnalyticsTracker.LifecycleEvents {
        switch self {
        case .install:
            return .applicationInstalled
        case .open:
            return .applicationOpened
        case .update:
            return .applicationUpdated
        }
    }
}
