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
        case preview(experienceID: String) // preview for draft content
        case show(experienceID: String)    // published content
        case debugger

        init?(url: URL, isSessionActive: Bool) {
            // supported paths:
            // appcues-{app_id}://sdk/experience_preview/{experience_id}
            // appcues-{app_id}://sdk/experience_content/{experience_id}
            // appcues-{app_id}://sdk/debugger

            let pathTokens = url.path.split(separator: "/").map { String($0) }

            if pathTokens.count == 2, pathTokens[0] == "experience_preview" {
                self = .preview(experienceID: pathTokens[1])
            } else if pathTokens.count == 2, pathTokens[0] == "experience_content", isSessionActive {
                // can only show content via deeplink when a session is active
                self = .show(experienceID: pathTokens[1])
            } else if pathTokens.count == 1, pathTokens[0] == "debugger" {
                self = .debugger
            } else {
                return nil
            }
        }
    }

    private let container: DIContainer
    private lazy var sessionMonitor = container.resolve(SessionMonitoring.self)

    private var action: Action?

    init(container: DIContainer) {
        self.container = container
    }

    func didHandleURL(_ url: URL) -> Bool {
        action = Action(url: url, isSessionActive: sessionMonitor.isActive)

        guard UIApplication.shared.topViewController() == nil else {
            // UIScene is already active and we can handle the action immediately.
            sceneDidActivate()
            return action != nil
        }

        if action != nil {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneDidActivate),
                name: UIScene.didActivateNotification,
                object: nil)
        }

        return action != nil
    }

    @objc
    private func sceneDidActivate() {
        guard let action = action else { return }

        switch action {
        case .preview(let experienceID):
            container.resolve(ExperienceLoading.self).load(experienceID: experienceID, published: false)
        case .show(let experienceID):
            container.resolve(ExperienceLoading.self).load(experienceID: experienceID, published: true)
        case .debugger:
            container.resolve(UIDebugging.self).show()
        }

        // Reset after handling to avoid handling notifications multiple times.
        self.action = nil
        NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
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
    @discardableResult
    func didHandleURL(_ URLContexts: Set<UIOpenURLContext>) -> Bool {
        guard let url = URLContexts.first(where: { $0.url.absoluteString.starts(with: "appcues") })?.url else { return false }
        return didHandleURL(url)
    }
}

extension URLComponents {
    func valueOf(_ queryItemName: String) -> String? {
        return queryItems?.first { $0.name == queryItemName }?.value
    }
}
