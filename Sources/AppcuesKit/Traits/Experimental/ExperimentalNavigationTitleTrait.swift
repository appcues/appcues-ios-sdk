//
//  ExperimentalNavigationTitleTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalNavigationTitleTrait: StepDecoratingTrait {
    static let type = "@experimental/navigation-title"

    let title: String

    required init?(config: [String: Any]?) {
        if let title = config?["title"] as? String {
            self.title = title
        } else {
            return nil
        }
    }

    func decorate(stepController: UIViewController) throws {
        stepController.title = title
    }
}
