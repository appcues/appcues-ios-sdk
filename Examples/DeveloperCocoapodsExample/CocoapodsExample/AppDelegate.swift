//
//  AppDelegate.swift
//  CocoapodsExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import AppcuesKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.

        // Automatically configure for push notifications
        Appcues.enableAutomaticPushConfig()

        // Or, manually configure for push notifications
        // setupPush(application: application)

        Appcues.registerCustomComponent(identifier: "liveStream", type: LiveStreamViewController.self)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after
        // application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // This example app uses UIScene's, so the SceneDelegate has the necessary implementation to handle URL Scheme links.
    /*
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        // Handle Appcues deep links.
        guard !Appcues.shared.didHandleURL(url) else { return true }
        return false
    }
    */

    // The Appcues link action uses this method to handle universal links.
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return false
        }

        if let sceneDelegate = application.connectedScenes.first(where: { $0.delegate is SceneDelegate })?.delegate as? SceneDelegate {
            return sceneDelegate.deepLinkNavigator.handle(url: incomingURL)
        } else {
            return false
        }
    }
}

extension Appcues {
    // Find your Appcues account ID in your account settings in Appcues Studio.
    // Find your Appcues application ID in your account settings under the Apps & Installation tab in Appcues Studio.
    static var shared = Appcues(config: Config(accountID: "500001", applicationID: "ab0bcfd3-17c8-40fa-95de-d643134cddd5")
        .apiHost(URL(string: "https://api.eu.appcues.net")!)
        .settingsHost(URL(string: "https://fast.eu.appcues.com")!))
}
