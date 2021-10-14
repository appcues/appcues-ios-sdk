//
//  ProfileViewController.swift
//  SegmentDestinationExample
//
//  Created by James Ellis on 10/13/21.
//

import UIKit
import Segment

class ProfileViewController: UIViewController {

    @IBOutlet private var givenNameTextField: UITextField!
    @IBOutlet private var familyNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Analytics.shared?.screen(title: "Update Profile")
    }

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        var properties: [String: String] = [:]

        if let givenName = givenNameTextField.text, !givenName.isEmpty {
            properties["givenName"] = givenName
        }

        if let familyName = familyNameTextField.text, !familyName.isEmpty {
            properties["familyName"] = familyName
        }

        Analytics.shared?.identify(userId: User.currentID, traits: properties)

        givenNameTextField.text = nil
        familyNameTextField.text = nil
    }
}
