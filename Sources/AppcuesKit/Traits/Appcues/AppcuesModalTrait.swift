//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalTrait: ContainerCreatingTrait, WrapperCreatingTrait, PresentingTrait {
    static let type = "@appcues/modal"

    let modalConfig: ModalConfig

    init?(config: [String: Any]?) {
        if let modalConfig = ModalConfig(config: config) {
            self.modalConfig = modalConfig
        } else {
            return nil
        }
    }

    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceStepContainer {
        ExperiencePagingViewController(stepControllers: stepControllers, groupID: nil)
    }

    func createWrapper(around containerController: ExperienceStepContainer) -> UIViewController {
        return modalConfig.createWrapper(around: containerController)
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        modalConfig.addBackdrop(backdropView: backdropView, to: wrapperController)
    }

    func present(viewController: UIViewController) throws {
        UIApplication.shared.topViewController()?.present(viewController, animated: true)
    }

    func remove(viewController: UIViewController) {
        viewController.dismiss(animated: true)
    }
}
