//
//  SceneDelegate.swift
//  CocoapodsExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import AppcuesKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    lazy var deepLinkNavigator = DeepLinkNavigator()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new
        // (see `application:configurationForConnectingSceneSession` instead).

        // Provide the scene to the the DeepLinkNavigator instance
        deepLinkNavigator.scene = scene

        // Handle Appcues deep links.
        let unhandledURLContexts = Appcues.shared.filterAndHandle(connectionOptions.urlContexts)

        // Handle app-specific deep links.
        deepLinkNavigator.handle(url: unhandledURLContexts.first?.url)

        // Handle app-specific universal links.
        connectionOptions.userActivities.forEach { userActivity in
            guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                let incomingURL = userActivity.webpageURL else {
                return
            }

            // Handle app-specific universal links.
            deepLinkNavigator.handle(url: incomingURL)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).

        // Remove the scene reference in the DeepLinkNavigator instance
        deepLinkNavigator.scene = nil
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        deepLinkNavigator.didBecomeActive()

        Appcues.shared.navigationDelegate = deepLinkNavigator
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle Appcues deep links.
        let unhandledURLContexts = Appcues.shared.filterAndHandle(URLContexts)

        // Handle app-specific deep links.
        deepLinkNavigator.handle(url: unhandledURLContexts.first?.url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL else {
            return
        }

        // Handle app-specific universal links.
        deepLinkNavigator.handle(url: incomingURL)
    }
}
