//
//  EventsViewController.swift
//  AppcuesExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import AppcuesKit

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
        Appcues.shared.track(name: "event1")
    }

    @IBAction private func buttonTwoTapped(_ sender: UIButton) {
        Appcues.shared.track(name: "event2")
    }

    @IBAction private func debugTapped(_ sender: Any) {
        Appcues.shared.debug()
    }
}
