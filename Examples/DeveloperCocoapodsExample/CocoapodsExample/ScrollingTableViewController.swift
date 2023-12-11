//
//  ScrollingTableViewController.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2023-12-11.
//

import UIKit
import AppcuesKit

class ScrollingTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Appcues.shared.screen(title: "Scrolling Table")
    }
}
