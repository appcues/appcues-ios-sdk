//
//  EmbedViewController.swift
//  AppcuesCocoapodsExample
//
//  Created by James Ellis on 8/15/22.
//

import UIKit
import AppcuesKit

class EmbedViewController: UIViewController {

    @IBOutlet private var appcuesFrame1: AppcuesFrameView!
    @IBOutlet private var appcuesFrame2: AppcuesFrameView!
    @IBOutlet private var appcuesFrame3: AppcuesFrameView!
    @IBOutlet private var appcuesFrame4: AppcuesFrameView!

    override func viewDidLoad() {
        super.viewDidLoad()

        Appcues.shared.register(frameID: "frame1", for: appcuesFrame1, on: self)
        Appcues.shared.register(frameID: "frame2", for: appcuesFrame2, on: self)
        Appcues.shared.register(frameID: "frame3", for: appcuesFrame3, on: self)
        Appcues.shared.register(frameID: "frame4", for: appcuesFrame4, on: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Embed Container")
    }

    @IBAction private func showTestHarness(_ sender: UIButton) {
        present(UINavigationController(rootViewController: EmbedTestHarnessViewController()), animated: true)
    }

}
