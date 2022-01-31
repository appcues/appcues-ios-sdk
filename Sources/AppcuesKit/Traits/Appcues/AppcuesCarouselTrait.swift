//
//  AppcuesCarouselTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesCarouselTrait: ContainerDecoratingTrait {
    static let type = "@appcues/carousel"

    let groupID: String?
    let progress: ProgressModel

    init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String
        self.progress = config?["progress", decodedAs: ProgressModel.self] ?? ProgressModel(type: .none, style: nil)
    }

    func decorate(containerController: ExperienceStepContainer) {
        guard let containerController = containerController as? ExperiencePagingViewController else { return }

        containerController.pageControl.isHidden = progress.type == .none
        containerController.pageControl.pageIndicatorTintColor = UIColor(dynamicColor: progress.style?.backgroundColor)
        containerController.pageControl.currentPageIndicatorTintColor = UIColor(dynamicColor: progress.style?.foregroundColor)
    }
}

extension AppcuesCarouselTrait {
    struct ProgressModel: Decodable {
        enum IndicatorType: String, Decodable {
            case none
            case dot
        }

        let type: IndicatorType
        let style: ExperienceComponent.Style?
    }
}
