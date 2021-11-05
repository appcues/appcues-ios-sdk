//
//  AppcuesCloseAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

/// Tags Appcues-specific view controllers to be ignored in automatic screen tracking.
internal protocol AppcuesController {}

internal struct AppcuesCloseAction: ExperienceAction {

    static let type = "@appcues/close"

    init?(config: [String: Any]?) {
        // no config expected
    }

    func execute(inContext appcues: Appcues) {
        guard let controller = UIApplication.shared.topViewController() else { return }
        if controller is AppcuesController {
            controller.dismiss(animated: true)
        }
    }
}
