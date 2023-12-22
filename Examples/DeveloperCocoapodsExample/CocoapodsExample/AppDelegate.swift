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

        registerForPush(application)

        Appcues.shared.analyticsDelegate = self

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

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("push deviceToken: \(token)")
        Appcues.shared.setPushToken(deviceToken)
    }

    private func registerForPush(_ application: UIApplication) {
        application.registerForRemoteNotifications()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
    }
}

extension AppDelegate: AppcuesAnalyticsDelegate {
    func didTrack(analytic: AppcuesKit.AppcuesAnalytic, value: String?, properties: [String: Any]?, isInternal: Bool) {
        if analytic == .event, value == "request_push" {
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    //        if #available(iOS 12.0, *) {
    //          options = UNAuthorizationOptions(rawValue: options.rawValue | UNAuthorizationOptions.provisional.rawValue)
    //        }
            center.requestAuthorization(options: options) { granted, error in
                print("Notification authorization, granted: \(granted), error: \(String(describing: error))")

                Appcues.shared.identify(userID: User.currentID, properties: ["pushStatus": granted ? "authorized" : "denied"])
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler(.banner)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        if let link = userInfo["appcues_deep_link_url"] as? String,
           let scene = UIApplication.shared.connectedScenes.first(where: { $0.delegate is SceneDelegate }),
           let sceneDelegate = scene.delegate as? SceneDelegate {
                sceneDelegate.deepLinkNavigator.handle(url: URL(string: link))
        }
    }

}

extension Appcues {
    static var shared = Appcues(config: Config(accountID: "17411", applicationID: "dd9ee4af-771e-419a-8de5-de77b93ccb54"))
}
