//
//  AppcuesRequestReviewAction.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-18.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
import StoreKit

@available(iOS 13.0, *)
internal class AppcuesRequestReviewAction: ExperienceAction {

    static let type = "@appcues/request-review"

    required init?(config: [String: Any]?) {
        // No config
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        if #available(iOS 14.0, *), let windowScene = UIApplication.shared.activeWindowScenes.first {
            SKStoreReviewController.requestReview(in: windowScene)
        } else {
            SKStoreReviewController.requestReview()
        }

        completion()
    }
}
