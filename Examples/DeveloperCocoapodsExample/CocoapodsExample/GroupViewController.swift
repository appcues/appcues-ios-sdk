//
//  GroupViewController.swift
//  AppcuesCocoapodsExample
//
//  Created by James Ellis on 12/14/21.
//

import UIKit
import AppcuesKit

class GroupViewController: UIViewController {
    @IBOutlet private var groupIDTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Update Group")
    }

    @IBAction private func saveGroupTapped(_ sender: Any) {
        view.endEditing(true)
        Appcues.shared.group(groupID: groupIDTextField.text, properties: [
            "test_user": true
        ])
    }
}
