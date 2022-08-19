//
//  EmbedViewController.swift
//  AppcuesSPMExample
//
//  Created by James Ellis on 8/15/22.
//

import UIKit
import AppcuesKit

class EmbedViewController: UIViewController {

    @IBOutlet private var embedSlot1: AppcuesView!
    @IBOutlet private var embedSlot2: AppcuesView!
    @IBOutlet private var embedSlot3: AppcuesView!
    @IBOutlet private var embedSlot4: AppcuesView!

    override func viewDidLoad() {
        super.viewDidLoad()

        Appcues.shared.registerEmbed(embedSlot1, embedId: "slot1", on: self)
        Appcues.shared.registerEmbed(embedSlot2, embedId: "slot2", on: self)
        Appcues.shared.registerEmbed(embedSlot3, embedId: "slot3", on: self)
        Appcues.shared.registerEmbed(embedSlot4, embedId: "slot4", on: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Embed Container")
    }
}
