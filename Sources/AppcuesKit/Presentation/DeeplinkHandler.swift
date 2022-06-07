//
//  DeeplinkHandler.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-28.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal protocol DeeplinkHandling: AnyObject {
    func didHandleURL(_ url: URL) -> Bool
}

@available(iOS 13.0, *)
internal class DeeplinkHandler: DeeplinkHandling {

    enum Action: Hashable {
        case preview(experienceID: String) // preview for draft content
        case show(experienceID: String)    // published content
        case debugger(destination: DebugDestination?)

        init?(url: URL, isSessionActive: Bool, applicationID: String) {
            let isValidScheme = url.scheme == "appcues-\(applicationID)" || url.scheme == "appcues-democues"
            guard isValidScheme, url.host == "sdk" else { return nil }

            // supported paths:
            // appcues-{app_id}://sdk/experience_preview/{experience_id}
            // appcues-{app_id}://sdk/experience_content/{experience_id}
            // appcues-{app_id}://sdk/debugger
            // appcues-{app_id}://sdk/debugger/fonts

            let pathTokens = url.path.split(separator: "/").map { String($0) }

            if pathTokens.count == 2, pathTokens[0] == "experience_preview" {
                self = .preview(experienceID: pathTokens[1])
            } else if pathTokens.count == 2, pathTokens[0] == "experience_content", isSessionActive {
                // can only show content via deeplink when a session is active
                self = .show(experienceID: pathTokens[1])
            } else if pathTokens.count >= 1, pathTokens[0] == "debugger" {
                self = .debugger(destination: DebugDestination(pathToken: pathTokens[safe: 1]))
            } else {
                return nil
            }
        }
    }

    private weak var container: DIContainer?
    private lazy var config = container?.resolve(Appcues.Config.self)

    // This is a set because a `SceneDelegate` has a `Set<UIOpenURLContext>` to handle.
    private var actionsToHandle: Set<Action> = []

    var topControllerGetting: TopControllerGetting = UIApplication.shared

    init(container: DIContainer) {
        self.container = container
    }

    func didHandleURL(_ url: URL) -> Bool {
        guard let applicationID = config?.applicationID,
              let action = Action(url: url, isSessionActive: container?.owner?.isActive ?? false, applicationID: applicationID) else {
            return false
        }

        if topControllerGetting.topViewController() != nil {
            // UIScene is already active and we can handle the action immediately.
            handle(action: action)
        } else if actionsToHandle.isEmpty {
            actionsToHandle.insert(action)

            // Set up a single observer to trigger handling any action(s).
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneDidActivate),
                name: UIScene.didActivateNotification,
                object: nil)
        } else {
            actionsToHandle.insert(action)
        }

        return true
    }

    private func handle(action: Action) {
        switch action {
        case .preview(let experienceID):
            container?.resolve(ExperienceLoading.self).load(experienceID: experienceID, published: false, completion: nil)
        case .show(let experienceID):
            container?.resolve(ExperienceLoading.self).load(experienceID: experienceID, published: true, completion: nil)
        case .debugger(let destination):
            container?.resolve(UIDebugging.self).show(destination: destination)
        }
    }

    @objc
    private func sceneDidActivate() {
        actionsToHandle.forEach(handle(action:))

        // Reset after handling to avoid handling notifications multiple times.
        self.actionsToHandle.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
    }
}

// Note: this is an extension compared to `Appcues.didHandle(_:)` because `UIOpenURLContext` in part of UIKit.
public extension Appcues {

    /// Verifies if an incoming URL is intended for the Appcues SDK.
    /// - Parameter URLContexts: One or more `UIOpenURLContext` objects.
    /// Each object contains one URL to open and any additional information needed to open that URL.
    /// - Returns: The set of `UIOpenURLContext` objects that were not intended for the Appcues SDK.
    ///
    /// If the `url` is an Appcues URL, this function may launch a flow preview or otherwise alter the UI state.
    ///
    /// This function is intended to be called added at the top of your `UISceneDelegate`'s `scene(_:openURLContexts:)` function:
    /// ```swift
    /// guard !<#appcuesInstance#>.filterAndHandle(URLContexts) else { return }
    /// ```
    @available(iOS 13.0, *)
    @discardableResult
    @objc
    func filterAndHandle(_ URLContexts: Set<UIOpenURLContext>) -> Set<UIOpenURLContext> {
        URLContexts.filter { !didHandleURL($0.url) }
    }
}
