import UIKit
import AppcuesKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        return true
    }

    ...
}

extension Appcues {
    static var shared: Appcues = {
        let config = Appcues.Config(
            accountID: <#APPCUES_ACCOUNT_ID#>,
            applicationID: <#APPCUES_APPLICATION_ID#>
        )
        .logging(true)
        return Appcues(config: config)
    }
}
