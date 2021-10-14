//
//  EventsViewController.swift
//  SegmentDestinationExample
//
//  Created by James Ellis on 10/13/21.
//

import UIKit
import Segment

class EventsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Analytics.shared.screen(title: "Trigger Events")
    }

    @IBAction private func buttonOneTapped(_ sender: UIButton) {
        Analytics.shared.track(name: "event1")
    }

    @IBAction private func buttonTwoTapped(_ sender: UIButton) {
        Analytics.shared.track(name: "event2")
    }
}
