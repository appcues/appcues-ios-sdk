import UIKit
import AppcuesKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self

        // Override point for customization after application launch.
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Appcues.shared.setPushToken(deviceToken)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if Appcues.shared.didReceiveNotification(response: response, completionHandler: completionHandler) {
            // NOTE: Appcues calls the completion handler if the notification is an Appcues notification.
            return
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }
}

extension Appcues {
    // Find your Appcues account ID in your account settings in Appcues Studio.
    // Find your Appcues application ID in your account settings under the Apps & Installation tab in Appcues Studio.
    static var shared = Appcues(config: Config(accountID: <#APPCUES_ACCOUNT_ID#>, applicationID: <#APPCUES_APPLICATION_ID#>))
}
