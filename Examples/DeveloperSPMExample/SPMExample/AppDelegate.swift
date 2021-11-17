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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // to opt-in for standard application lifecycle events, the SDK must be
        // initialzed and have its trackLifecycle() function called during app startup here
        Appcues.shared.trackLifecycle()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
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
        // Handle Appcues deeplinks.
        guard !Appcues.shared.didHandleURL(url) else { return true }
        return false
    }
    */
}

extension Appcues {
    // Find your Appcues account ID in your account settings in Appcues Studio.
    static var shared = Appcues(config: Config(accountID: <#APPCUES_ACCOUNT_ID#>))
}
