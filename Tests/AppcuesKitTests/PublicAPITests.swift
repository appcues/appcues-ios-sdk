//
//  PublicAPITests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-04-05.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
import SwiftUI
import AppcuesKit

/// This test class exists to verify the full breadth of the public API contract. It does not assert any specific results.
/// If this test class fails to compile, that indicates a breaking change in the public API.
class PublicAPITests: XCTestCase {

    func testAPI() throws {
        let config = Appcues.Config(accountID: "12345", applicationID: "abc")
            .logging(true)
            .apiHost(URL(string: "localhost")!)
            .sessionTimeout(3600)
            .activityStorageMaxSize(25)
            .activityStorageMaxAge(3600)
            .urlSession(URLSession.shared)
            .anonymousIDFactory({ UUID().uuidString })
            .additionalAutoProperties(["test": "value"])
            .enableUniversalLinks(true)

        let appcuesInstance = Appcues(config: config)

        let experienceDelegate = SampleExperienceDelegate()
        appcuesInstance.experienceDelegate = experienceDelegate

        let analyticsDelegate = SampleAnalyticsDelegate()
        appcuesInstance.analyticsDelegate = analyticsDelegate

        let navigationDelegate = SampleNavigationDelegate()
        appcuesInstance.navigationDelegate = navigationDelegate

        _ = appcuesInstance.version()

        appcuesInstance.identify(userID: "userID")
        appcuesInstance.identify(userID: "userID", properties: ["test": "value"])

        appcuesInstance.group(groupID: nil)
        appcuesInstance.group(groupID: "groupID")
        appcuesInstance.group(groupID: "groupID", properties: ["test": "value"])

        appcuesInstance.anonymous()
        appcuesInstance.anonymous(properties: ["test": "value"])

        appcuesInstance.reset()

        appcuesInstance.track(name: "event")
        appcuesInstance.track(name: "event", properties: ["test": "value"])

        appcuesInstance.screen(title: "screen")
        appcuesInstance.screen(title: "screen", properties: ["test": "value"])

        appcuesInstance.show(experienceID: "12345")
        appcuesInstance.show(experienceID: "12345") { success, error in
            print(success, error)
        }

        appcuesInstance.register(trait: SampleTrait.self)
        appcuesInstance.register(action: SampleAction.self)

        appcuesInstance.debug()

        appcuesInstance.trackScreens()

        _ = appcuesInstance.didHandleURL(URL(string: "https://api.appcues.net")!)

        if #available(iOS 13.0, *) {
            _ = appcuesInstance.filterAndHandle(Set())
        }

        _ = Font.Design.allCases
        _ = Font.Design.default.description
        _ = Font.Weight.allCases
        _ = Font.Weight.regular.description
    }
}

class SampleExperienceDelegate: AppcuesExperienceDelegate {
    func canDisplayExperience(experienceID: String) -> Bool {
        true
    }

    func experienceWillAppear() {
        // no-op
    }

    func experienceDidAppear() {
        // no-op
    }

    func experienceWillDisappear() {
        // no-op
    }

    func experienceDidDisappear() {
        // no-op
    }


}

class SampleAnalyticsDelegate: AppcuesAnalyticsDelegate {
    func didTrack(analytic: AppcuesAnalytic, value: String?, properties: [String : Any]?, isInternal: Bool) {
        // Do not add `@unknown default` here, since we want to know about new cases
        switch analytic {
        case .event:
            break
        case .screen:
            break
        case .identify:
            break
        case .group:
            break
        }
    }
}

class SampleNavigationDelegate: AppcuesNavigationDelegate {
    func navigate(to url: URL, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

class SampleTrait: ExperienceTrait, StepDecoratingTrait, ContainerCreatingTrait, ContainerDecoratingTrait, BackdropDecoratingTrait, WrapperCreatingTrait, PresentingTrait {

    static var type: String = "@sample/trait"

    weak var metadataDelegate: TraitMetadataDelegate?

    required init?(config: DecodingExperienceConfig, level: ExperienceTraitLevel) {
        // Do not add `@unknown default` here, since we want to know about new cases
        switch level {
        case .experience:
            break
        case .group:
            break
        case .step:
            break
        }

        let _: String? = config["key"]
    }

    // MARK: StepDecoratingTrait
    func decorate(stepController: UIViewController) throws {
        // no-op
    }

    // MARK: ContainerCreatingTrait
    func createContainer(for stepControllers: [UIViewController], with pageMonitor: PageMonitor) throws -> ExperienceContainerViewController {
        return SampleExperienceContainerViewController(stepControllers: stepControllers, pageMonitor: pageMonitor)
    }

    // MARK: ContainerDecoratingTrait
    func decorate(containerController: ExperienceContainerViewController) throws {
        // no-op
    }

    func undecorate(containerController: AppcuesKit.ExperienceContainerViewController) throws {
        // no-op
    }

    // MARK: BackdropDecoratingTrait
    func decorate(backdropView: UIView) throws {
        // no-op
    }

    func undecorate(backdropView: UIView) throws {
        // no-op
    }

    // MARK: WrapperCreatingTrait
    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
        return containerController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        // no-op
    }

    // MARK: PresentingTrait
    func present(viewController: UIViewController, completion: (() -> Void)?) throws {
        completion?()
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        completion?()
    }
}

class SampleExperienceContainerViewController: ExperienceContainerViewController {

    weak var lifecycleHandler: ExperienceContainerLifecycleHandler?
    let pageMonitor: PageMonitor

    init(stepControllers: [UIViewController], pageMonitor: PageMonitor) {
        self.pageMonitor = pageMonitor

        super.init(nibName: nil, bundle: nil)

        pageMonitor.addObserver { [weak self] newIndex, oldIndex in
            self?.lifecycleHandler?.containerNavigated(from: oldIndex, to: newIndex)
        }

        // PageMonitor getters
        print(pageMonitor.currentPage)
        print(pageMonitor.numberOfPages)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func navigate(to pageIndex: Int, animated: Bool) {
        pageMonitor.set(currentPage: pageIndex)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleHandler?.containerWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleHandler?.containerDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifecycleHandler?.containerWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifecycleHandler?.containerDidDisappear()
    }
}


class SampleAction: ExperienceAction {
    static var type: String = "@sample/action"

    required init?(config: DecodingExperienceConfig) {
        // no-op
    }

    func execute(inContext appcues: Appcues, completion: @escaping () -> Void) {
        completion()
    }
}
