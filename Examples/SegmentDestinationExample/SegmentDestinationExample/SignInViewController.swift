//
//  SignInViewController.swift
//  SegmentDestinationExample
//
//  Created by James Ellis on 10/13/21.
//

import UIKit
import Segment

enum User {
    static var currentID = "default-00000"
}

class SignInViewController: UIViewController {

    @IBOutlet private var userIDTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDTextField.text = User.currentID
    }

    @IBAction private func signInTapped(_ sender: UIButton) {
        let userID = userIDTextField.text ?? User.currentID
        Analytics.shared.identify(userId: userID)

        User.currentID = userID
    }

    @IBAction private func signOutAction(unwindSegue: UIStoryboardSegue) {
        // Unwind to Sign In
    }
}
