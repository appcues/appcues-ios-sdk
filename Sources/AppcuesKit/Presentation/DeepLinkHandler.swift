//
//  DeepLinkHandler.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-28.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol DeepLinkHandling: AnyObject {
    func didHandleURL(_ url: URL) -> Bool
}

internal class DeepLinkHandler: DeepLinkHandling {

    enum Action: Hashable {
        /// preview for draft content
        case preview(experienceID: String, queryItems: [URLQueryItem])
        /// published content
        case show(experienceID: String, queryItems: [URLQueryItem])
        /// preview for draft push content
        case pushPreview(id: String, queryItems: [URLQueryItem])
        /// published push content
        case pushContent(id: String)
        case debugger(destination: DebugDestination?)
        case verifyInstall(id: String)
        case captureScreen(token: String)

        init?(url: URL, isSessionActive: Bool, applicationID: String) {
            let isValidScheme = url.scheme == "appcues-\(applicationID)" || url.scheme == "appcues-democues"
            guard isValidScheme, url.host == "sdk" else { return nil }

            // supported paths:
            // appcues-{app_id}://sdk/experience_preview/{experience_id}?locale_id={localeID}
            // appcues-{app_id}://sdk/experience_content/{experience_id}
            // appcues-{app_id}://sdk/push_preview/{id}?<query_params>
            // appcues-{app_id}://sdk/push_content/{id}
            // appcues-{app_id}://sdk/debugger
            // appcues-{app_id}://sdk/debugger/fonts
            // appcues-{app_id}://sdk/verify/{token}
            // appcues-{app_id}://sdk/capture_screen

            let pathTokens = url.path.split(separator: "/").map { String($0) }

            if pathTokens.count == 2, pathTokens[0] == "experience_preview" {
                self = .preview(experienceID: pathTokens[1], queryItems: url.queryItems)
            } else if pathTokens.count == 2, pathTokens[0] == "experience_content", isSessionActive {
                // can only show content via deep link when a session is active
                self = .show(experienceID: pathTokens[1], queryItems: url.queryItems)
            } else if pathTokens.count == 2, pathTokens[0] == "push_preview" {
                self = .pushPreview(id: pathTokens[1], queryItems: url.queryItems)
            } else if pathTokens.count == 2, pathTokens[0] == "push_content" {
                self = .pushContent(id: pathTokens[1])
            } else if pathTokens.count >= 1, pathTokens[0] == "debugger" {
                self = .debugger(destination: DebugDestination(pathToken: pathTokens[safe: 1]))
            } else if pathTokens.count == 2, pathTokens[0] == "verify" {
                self = .verifyInstall(id: pathTokens[1])
            } else if pathTokens.count == 1, pathTokens[0] == "capture_screen", let token = url.queryValue(for: "token") {
                self = .captureScreen(token: token)
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
              let action = Action(
                url: url,
                isSessionActive: container?.owner?.isActive ?? false,
                applicationID: applicationID
              ) else {
            return false
        }

        dispatch(action: action)

        return true
    }

    private func dispatch(action: Action) {
        if topControllerGetting.hasActiveWindowScenes {
            // UIScene is already active and we can handle the action immediately.
            Task {
                await handle(action: action)
            }
        } else if actionsToHandle.isEmpty {
            actionsToHandle.insert(action)

            // Set up a single observer to trigger handling any action(s).
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneDidActivate),
                name: UIScene.didActivateNotification,
                object: nil
            )
        } else {
            actionsToHandle.insert(action)
        }
    }

    private func handle(action: Action) async {
        switch action {
        case let .preview(experienceID, queryItems):
            do {
                try await container?.resolve(ContentLoading.self).load(
                    experienceID: experienceID,
                    published: false,
                    queryItems: queryItems,
                    trigger: .preview
                )
            } catch {
                await handleExperiencePreviewError(error: error)
            }
        case let .show(experienceID, queryItems):
            try? await container?.resolve(ContentLoading.self).load(
                experienceID: experienceID,
                published: true,
                queryItems: queryItems,
                trigger: .deepLink
            )
        case let .pushPreview(id, queryItems):
            do {
                try await container?.resolve(ContentLoading.self).loadPush(
                    id: id,
                    published: false,
                    queryItems: queryItems
                )
            } catch {
                await handlePushPreviewError(error: error)
            }
        case let .pushContent(id):
            try? await container?.resolve(ContentLoading.self).loadPush(
                id: id,
                published: true,
                queryItems: []
            )
        case .debugger(let destination):
            await container?.resolve(UIDebugging.self).show(mode: .debugger(destination))
        case .verifyInstall(let token):
            await container?.resolve(UIDebugging.self).verifyInstall(token: token)
        case .captureScreen(let token):
            await container?.resolve(UIDebugging.self).show(mode: .screenCapture(.bearer(token)))
        }
    }

    private func handleExperiencePreviewError(error: Error) async {
        let message: String
        switch error {
        case let ExperienceRendererError.renderDeferred(context, experience):
            message = "Please navigate to the screen with \(context.description) to preview \(experience.name)."
        case NetworkingError.nonSuccessfulStatusCode(404, _):
            message = "Mobile flow not found."
        case is NetworkingError:
            message = "Error loading mobile flow preview."
        case let ExperienceStateMachine.ExperienceError.step(experience, _, errorMessage, _),
            let ExperienceStateMachine.ExperienceError.experience(experience, errorMessage):
            message = "Preview of \(experience.name) failed: \(errorMessage)"
        default:
            message = "Mobile flow preview failed."
        }

        let toast = DebugToast(message: .custom(text: message), style: .failure)
        await container?.resolve(UIDebugging.self).showToast(toast)
    }

    private func handlePushPreviewError(error: Error) async {
        let message: String
        switch error {
        case NetworkingError.nonSuccessfulStatusCode(404, _):
            message = "Push notification not found."
        case is NetworkingError:
            message = "Error loading push notification preview."
        default:
            message = "Push notification preview failed."
        }

        let toast = DebugToast(message: .custom(text: message), style: .failure)
        await container?.resolve(UIDebugging.self).showToast(toast)
    }

    @objc
    private func sceneDidActivate() {
        Task {
            for action in actionsToHandle {
                await handle(action: action)
            }

            // Reset after handling to avoid handling notifications multiple times.
            self.actionsToHandle.removeAll()
            // Xcode 15 requires `await`
            await NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
        }
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
    @discardableResult
    @objc
    func filterAndHandle(_ URLContexts: Set<UIOpenURLContext>) -> Set<UIOpenURLContext> {
        URLContexts.filter { !didHandleURL($0.url) }
    }
}

private extension URL {
    var queryItems: [URLQueryItem] {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems ?? []
    }

    func queryValue(for name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name.lowercased() == name }?
            .value
    }
}
