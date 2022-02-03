//
//  AppcuesCarouselTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesCarouselTrait: ContainerCreatingTrait {
    static let type = "@appcues/carousel"

    let groupID: String?

    init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String
    }

    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceStepContainer {
        ExperiencePagingViewController(stepControllers: stepControllers, targetPageIndex: targetPageIndex)
    }
}
