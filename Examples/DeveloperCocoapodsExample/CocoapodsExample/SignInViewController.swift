//
//  SignInViewController.swift
//  CocoapodsExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import Appcues

enum User {
    static var currentID = "default-00000"
}

class SignInViewController: UIViewController {

    @IBOutlet private var userIDTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDTextField.text = User.currentID
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Sign In", properties: [:])
    }

    @IBAction private func signInTapped(_ sender: UIButton) {
        let userID = userIDTextField.text ?? User.currentID
        Appcues.shared.identify(
            userID: userID,
            properties: [:])

        User.currentID = userID
    }
}
