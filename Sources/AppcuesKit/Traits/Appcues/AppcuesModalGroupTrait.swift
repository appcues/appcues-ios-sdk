//
//  AppcuesModalGroupTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalGroupTrait: ContainerTrait {
    static let type = "@appcues/modal-group"

    let modalConfig: ModalConfig
    let groupID: String
    let progress: ProgressModel?
    let swipeEnabled: Bool

    init?(config: [String: Any]?) {
        if let modalConfig = ModalConfig(config: config), let groupID = config?["groupID"] as? String {
            self.modalConfig = modalConfig
            self.groupID = groupID
        } else {
            return nil
        }

        self.progress = config?["progress", decodedAs: ProgressModel.self]
        self.swipeEnabled = config?["swipeEnabled"] as? Bool ?? true
    }

    func apply(to containerController: UIViewController, wrappedBy wrappingController: UIViewController) -> UIViewController {
        guard let containerController = containerController as? ExperiencePagingViewController else { return wrappingController }

        guard containerController.groupID == groupID else { return wrappingController }

        if let progress = progress {
            containerController.pageControl.isHidden = progress.type == .none
            containerController.pageControl.pageIndicatorTintColor = UIColor(dynamicColor: progress.style?.backgroundColor)
            containerController.pageControl.currentPageIndicatorTintColor = UIColor(dynamicColor: progress.style?.foregroundColor)
        }

        return modalConfig.apply(to: containerController, wrappedBy: wrappingController)
    }
}

extension AppcuesModalGroupTrait {
    struct ProgressModel: Decodable {
        enum IndicatorType: String, Decodable {
            case none
            case dot
        }

        let type: IndicatorType
        let style: ExperienceComponent.Style?
    }
}
