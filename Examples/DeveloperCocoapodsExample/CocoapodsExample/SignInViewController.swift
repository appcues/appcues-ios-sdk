//
//  SignInViewController.swift
//  CocoapodsExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import Appcues

class SignInViewController: UIViewController {

    private static let defaultUserID = "default-00000"

    @IBOutlet private var userIDTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDTextField.text = SignInViewController.defaultUserID
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Sign In", properties: [:])
    }

    @IBAction private func signInTapped(_ sender: UIButton) {
        Appcues.shared.identify(
            userID: userIDTextField.text ?? SignInViewController.defaultUserID,
            properties: [:])
    }
}
