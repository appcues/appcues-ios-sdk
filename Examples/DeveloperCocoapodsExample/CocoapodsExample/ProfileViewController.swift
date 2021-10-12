//
//  ProfileViewController.swift
//  AppcuesExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import Appcues

class ProfileViewController: UIViewController {

    @IBOutlet private var givenNameTextField: UITextField!
    @IBOutlet private var familyNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Update Profile", properties: [:])
    }

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        var properties: [String: String] = [:]

        if let givenName = givenNameTextField.text, !givenName.isEmpty {
            properties["givenName"] = givenName
        }

        if let familyName = familyNameTextField.text, !familyName.isEmpty {
            properties["familyName"] = familyName
        }

        // The web SDK doesn't allow setting custom user properties apart from the identify call.
        // TODO: This doesn't grab the user ID from the sign in page
        Appcues.shared.identify(userID: "default-00000", properties: properties)

        givenNameTextField.text = nil
        familyNameTextField.text = nil
    }
}
