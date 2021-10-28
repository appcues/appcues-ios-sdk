//
//  DeeplinkHandler.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-28.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class DeeplinkHandler {

    enum Action {
        case preview(contentID: String)
        case debugger

        init?(url: URL) {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

            if components.host == "preview", let contentID = components.valueOf("contentID") {
                self = .preview(contentID: contentID)
            } else if components.host == "debugger" {
                self = .debugger
            } else {
                return nil
            }
        }
    }

    private let container: DIContainer

    private var action: Action?

    /// Closure to allow this class to manage it's own lifecycle.
    private var retainClosure: (() -> Void)?

    init(container: DIContainer) {
        self.container = container
    }

    func didHandleURL(_ url: URL) -> Bool {
        action = Action(url: url)

        if action != nil {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneDidActivate),
                name: UIScene.didActivateNotification,
                object: nil)

            // A useless block that creates a memory retain cycle by capturing `self`.
            // This must be cleared after the notification is handled once.
            retainClosure = { _ = self.action == nil }
        }

        return action != nil
    }

    @objc
    private func sceneDidActivate(notification: Notification) {
        // Remove the retain cycle to allow this instance of `DeeplinkHandler` to deinit.
        self.retainClosure = nil

        switch action! {
        case .preview(let contentID):
            container.resolve(ExperienceLoader.self).load(contentID: contentID)
        case .debugger:
            container.resolve(UIDebugger.self).show()
        }
    }
}

// Note: this is an extension compared to `Appcues.didHandle(_:)` because `UIOpenURLContext` in part of UIKit.
public extension Appcues {

    /// Verifies if an incoming URL is intended for the Appcues SDK.
    /// - Parameter URLContexts: One or more `UIOpenURLContext` objects.
    /// Each object contains one URL to open and any additional information needed to open that URL.
    /// - Returns: `true` if the URL matches the Appcues URL Scheme or `false` if the URL is not known by the Appcues SDK.
    ///
    /// If the `url` is an Appcues URL, this function may launch a flow preview or otherwise alter the UI state.
    ///
    /// This function is intended to be called added at the top of your `UISceneDelegate`'s `scene(_:openURLContexts:)` function:
    /// ```swift
    /// guard !<#appcuesInstance#>.didHandleURL(URLContexts) else { return }
    /// ```
    func didHandleURL(_ URLContexts: Set<UIOpenURLContext>) -> Bool {
        guard let url = URLContexts.first?.url else { return false }
        return didHandleURL(url)
    }
}

extension URLComponents {
    func valueOf(_ queryItemName: String) -> String? {
        return queryItems?.first { $0.name == queryItemName }?.value
    }
}
