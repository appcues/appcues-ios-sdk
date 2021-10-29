//
//  ProfileViewController.swift
//  AppcuesExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import AppcuesKit

class ProfileViewController: UIViewController {

    @IBOutlet private var givenNameTextField: UITextField!
    @IBOutlet private var familyNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Update Profile")
    }

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        var properties: [String: String] = [:]

        if let givenName = givenNameTextField.text, !givenName.isEmpty {
            properties["givenName"] = givenName
        }

        if let familyName = familyNameTextField.text, !familyName.isEmpty {
            properties["familyName"] = familyName
        }

        Appcues.shared.identify(userID: User.currentID, properties: properties)

        givenNameTextField.text = nil
        familyNameTextField.text = nil
    }
}
