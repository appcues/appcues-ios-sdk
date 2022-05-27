//
//  ExperimentalTabBarItemTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalTabBarItemTrait: StepDecoratingTrait {
    static let type = "@experimental/tab-bar-item"

    let title: String
    let icon: UIImage?

    required init?(config: [String: Any]?) {
        if let title = config?["title"] as? String {
            self.title = title
        } else {
            return nil
        }

        self.icon = UIImage(systemName: config?["symbolName"] as? String ?? "")
    }

    func decorate(stepController: UIViewController) throws {
        stepController.tabBarItem = UITabBarItem(title: title, image: icon, tag: 0)
    }
}
