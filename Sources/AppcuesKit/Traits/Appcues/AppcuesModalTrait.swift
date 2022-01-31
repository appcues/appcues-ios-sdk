//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalTrait: WrapperCreatingTrait {
    static let type = "@appcues/modal"

    let modalConfig: ModalConfig

    init?(config: [String: Any]?) {
        if let modalConfig = ModalConfig(config: config) {
            self.modalConfig = modalConfig
        } else {
            return nil
        }
    }

    func createWrapper(around containerController: ExperienceStepContainer) -> UIViewController {
        return modalConfig.createWrapper(around: containerController)
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        modalConfig.addBackdrop(backdropView: backdropView, to: wrapperController)
    }
}
