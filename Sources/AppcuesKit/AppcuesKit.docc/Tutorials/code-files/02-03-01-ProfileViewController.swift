import UIKit
import AppcuesKit

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Profile")
    }

    ...

    /// Handle a button tap.
    @IBAction private func expandButtonTapped(_ sender: UIButton) {
        ...

    }

    /// Handle a successful sign in attempt.
    @IBAction private func signOutTapped(_ sender: UIButton) {
        ...

        Appcues.shared.reset()
    }
}
