//
//  SignInViewController.swift
//  CocoapodsExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import AppcuesKit

enum User {
    static var currentID = "default-00000"
}

class SignInViewController: UIViewController {

    private var pushStatus = "unknown"

    @IBOutlet private var userIDTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // determine push status
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                // Notification permission has not been asked yet, go for it!
                self.pushStatus = "notDetermined"
            } else if settings.authorizationStatus == .denied {
                // Notification permission was previously denied, go to settings & privacy to re-enable
                self.pushStatus = "denied"
            } else if settings.authorizationStatus == .authorized {
                // Notification permission was already granted
                self.pushStatus = "authorized"
            }
        }

        userIDTextField.text = User.currentID
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Sign In")
    }

    @IBAction private func signInTapped(_ sender: UIButton) {
        let userID = userIDTextField.text ?? User.currentID

        Appcues.shared.identify(userID: userID, properties: ["pushStatus": pushStatus])

        User.currentID = userID
    }

    @IBAction private func signOutAction(unwindSegue: UIStoryboardSegue) {
        // Unwind to Sign In
        Appcues.shared.reset()
    }

    @IBAction private func anonymousUserTapped(_ sender: Any) {
        Appcues.shared.anonymous()
    }
}
