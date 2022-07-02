import UIKit
import AppcuesKit

class SignInViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    ...

    /// Handle a successful sign in attempt.
    func signInSuccess(user: User) {
        Appcues.shared.identify(
            userID: user.id,
            properties: [
                // Add any user-specific properties to pass to Appcues.
                // These values can be used to segment users and target experiences.
                "Membership Level": user.level
            ]
        )

        ...
    }
}
