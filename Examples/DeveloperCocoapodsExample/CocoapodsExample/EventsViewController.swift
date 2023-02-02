//
//  EventsViewController.swift
//  AppcuesExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import AppcuesKit

class EventsViewController: UIViewController {
    @IBOutlet private var btnEvent3: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        btnEvent3.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Trigger Events")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.btnEvent3.isHidden = false
        }
    }

    @IBAction private func buttonOneTapped(_ sender: UIButton) {
        Appcues.shared.track(name: "event1")
    }

    @IBAction private func buttonTwoTapped(_ sender: UIButton) {
        if #available(iOS 14.0, *) {
            show(TooltipPlaygroundVC(instance: Appcues.shared), sender: self)
        } else {
            Appcues.shared.track(name: "event2")
        }
    }

    @IBAction private func buttonThreeTapped(_ sender: UIButton) {
        Appcues.shared.track(name: "event3")
    }

    @IBAction private func debugTapped(_ sender: Any) {
        Appcues.shared.debug()
    }
}
