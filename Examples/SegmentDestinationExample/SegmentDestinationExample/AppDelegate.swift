//
//  AppDelegate.swift
//  SegmentDestinationExample
//
//  Created by James Ellis on 10/13/21.
//

import UIKit
import Segment

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let configuration = Configuration(writeKey: <#SEGMENT_WRITE_KEY#>)
            .trackApplicationLifecycleEvents(true)
            .flushAt(1)

        let analytics = Analytics(configuration: configuration)

        // Add the Appcues destination plugin
        analytics.add(plugin: AppcuesDestination())

        Analytics.shared = analytics

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

}

extension Analytics {
    static var shared: Analytics?
}
