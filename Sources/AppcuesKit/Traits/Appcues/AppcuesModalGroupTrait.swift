//
//  AppcuesModalGroupTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalGroupTrait: ConditionalGroupingTrait, JoiningTrait,
                                        ContainerCreatingTrait, ContainerDecoratingTrait, WrapperCreatingTrait, PresentingTrait {
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

    func join(initialStep stepIndex: Int, in experience: Experience) -> [Experience.Step] {
        let modalGroupID = experience.steps[stepIndex].traits.groupID(type: Self.type)
        return experience.steps.filter { $0.traits.groupID(type: Self.type) == modalGroupID }
    }

    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) -> ExperienceStepContainer {
        let pagingViewController = ExperiencePagingViewController(
            stepControllers: stepControllers,
            groupID: groupID)

        if targetPageIndex != 0 {
            pagingViewController.targetPageIndex = targetPageIndex
        }

        return pagingViewController
    }

    func decorate(containerController: ExperienceStepContainer) {
        guard let containerController = containerController as? ExperiencePagingViewController else { return }
        guard containerController.groupID == groupID else { return }

        if let progress = progress {
            containerController.pageControl.isHidden = progress.type == .none
            containerController.pageControl.pageIndicatorTintColor = UIColor(dynamicColor: progress.style?.backgroundColor)
            containerController.pageControl.currentPageIndicatorTintColor = UIColor(dynamicColor: progress.style?.foregroundColor)
        }
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
