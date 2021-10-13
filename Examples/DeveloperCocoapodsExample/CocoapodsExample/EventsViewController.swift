//
//  EventsViewController.swift
//  AppcuesExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import Appcues

class EventsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Trigger Events")
    }

    @IBAction private func buttonOneTapped(_ sender: UIButton) {
        Appcues.shared.track(event: "event1")
    }

    @IBAction private func buttonTwoTapped(_ sender: UIButton) {
        Appcues.shared.track(event: "event2")
    }
}
