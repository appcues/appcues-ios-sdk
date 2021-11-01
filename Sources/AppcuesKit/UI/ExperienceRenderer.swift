//
//  ExperienceRenderer.swift
//  Appcues
//
//  Created by Matt on 2021-10-20.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class ExperienceRenderer {

    private let config: Appcues.Config
    private let styleLoader: StyleLoader

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.styleLoader = container.resolve(StyleLoader.self)
    }

    // Show a specified flow model on top of the current application.
    func show(flow: Flow) {
        guard let modalStepGroup: ModalGroup = flow.steps.compactMap({ $0 as? ModalGroup }).first else {
            // Currently only supporting a single ModalGroup. Additional modal groups or other types aren't supported yet.
            self.config.logger.error("Cannot show flow %{public}s because it has no modal groups", flow.id)
            return
        }

        DispatchQueue.main.async {
            guard let topController = UIApplication.shared.topViewController() else {
                self.config.logger.error("Could not determine top view controller")
                return
            }

            let viewController = ModalGroupViewController(modalStepGroup: modalStepGroup, styleLoader: self.styleLoader)
            topController.present(viewController, animated: true)
        }
    }
}
