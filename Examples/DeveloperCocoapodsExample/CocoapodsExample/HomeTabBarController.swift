//
//  HomeTabBarController.swift
//  AppcuesCocoapodsExample
//
//  Created by James Ellis on 1/19/23.
//

import UIKit

class HomeTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // workaround due to tabBarItem not supporting accessibility in typical fashion
        let tabBarControls = tabBar.subviews.compactMap { $0 as? UIControl }
        let tabBarItems = tabBar.items ?? []
        // this takes the accessibility info from each tabBarItem and applies it to the
        // underlying tab controls that get rendered so our selectors can find them
        zip(tabBarControls, tabBarItems).forEach { control, item in
            control.accessibilityIdentifier = item.accessibilityIdentifier
            control.accessibilityLabel = item.accessibilityLabel
            control.tag = item.tag
        }
    }
}
