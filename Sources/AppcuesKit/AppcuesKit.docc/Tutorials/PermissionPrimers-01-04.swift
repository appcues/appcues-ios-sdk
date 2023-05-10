import UIKit
import AppcuesKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.

        Appcues.shared.analyticsDelegate = self

        return true
    }
}

extension AppDelegate: AppcuesAnalyticsDelegate {
    func didTrack(analytic: AppcuesKit.AppcuesAnalytic, value: String?, properties: [String: Any]?, isInternal: Bool) {
    }
}

extension Appcues {
    // Find your Appcues account ID in your account settings in Appcues Studio.
    // Find your Appcues application ID in your account settings under the Apps & Installation tab in Appcues Studio.
    static var shared = Appcues(config: Config(accountID: <#APPCUES_ACCOUNT_ID#>, applicationID: <#APPCUES_APPLICATION_ID#>))
}
