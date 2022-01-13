//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalTrait: ContainerExperienceTrait {
    static let type = "@appcues/modal"

    let modalConfig: ModalConfig

    init?(config: [String: Any]?) {
        if let modalConfig = ModalConfig(config: config) {
            self.modalConfig = modalConfig
        } else {
            return nil
        }
    }

    func apply(to containerController: UIViewController, wrappedBy wrappingController: UIViewController) -> UIViewController {
        return modalConfig.apply(to: containerController, wrappedBy: wrappingController)
    }
}
