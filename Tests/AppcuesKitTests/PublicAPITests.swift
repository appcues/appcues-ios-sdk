//
//  PublicAPITests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-04-05.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
import AppcuesKit

/// This test class exists to verify the full breadth of the public API contract. It does not assert any specific results.
/// If this test class fails to compile, that indicates a breaking change in the public API.
class PublicAPITests: XCTestCase {

    func testAPI() throws {
        if #available(iOS 13.0, *) {
            Appcues.elementTargeting = SampleElementTargeting()
        }

        _ = AppcuesElementSelector().evaluateMatch(for: AppcuesElementSelector())

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
    }
}

class SampleElementTargeting: AppcuesElementTargeting {
    func captureLayout() -> AppcuesViewElement? {
        let elementWithDisplayName = AppcuesViewElement(
            x: 0,
            y: 0,
            width: 100,
            height: 100,
            type: "view",
            selector: AppcuesElementSelector(),
            children: nil,
            displayName: "display name")

        return AppcuesViewElement(
            x: 0,
            y: 0,
            width: 100,
            height: 100,
            type: "view",
            selector: AppcuesElementSelector(),
            children: [elementWithDisplayName])
    }

    func inflateSelector(from properties: [String : String]) -> AppcuesElementSelector? {
        return AppcuesElementSelector()
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
    func navigate(to url: URL, openExternally: Bool, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

class SampleTrait: AppcuesExperienceTrait, AppcuesStepDecoratingTrait, AppcuesContainerCreatingTrait, AppcuesContainerDecoratingTrait, AppcuesBackdropDecoratingTrait, AppcuesWrapperCreatingTrait, AppcuesPresentingTrait {

    struct Config: Decodable {
        let key: String?
    }

    static var type: String = "@sample/trait"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        // Do not add `@unknown default` here, since we want to know about new cases
        switch configuration.level {
        case .experience:
            break
        case .group:
            break
        case .step:
            break
        }

        let config = configuration.decode(Config.self)
        _ = config?.key

        metadataDelegate?.unset(keys: ["key"])
        metadataDelegate?.set(["key": "value"])
        metadataDelegate?.publish()

        metadataDelegate?.registerHandler(for: "trait", animating: true) { metadata in
            print(metadata)
            let newValue: String? = metadata["key"]
            let oldValue: String? = metadata[previous: "key"]
        }
        metadataDelegate?.removeHandler(for: "trait")
    }

    // MARK: AppcuesStepDecoratingTrait
    func decorate(stepController: UIViewController) throws {
        // no-op
    }

    // MARK: AppcuesContainerCreatingTrait
    func createContainer(for stepControllers: [UIViewController], with pageMonitor: AppcuesExperiencePageMonitor) throws -> AppcuesExperienceContainerViewController {
        return SampleExperienceContainerViewController(stepControllers: stepControllers, pageMonitor: pageMonitor)
    }

    // MARK: AppcuesContainerDecoratingTrait
    func decorate(containerController: AppcuesExperienceContainerViewController) throws {
        // no-op
    }

    func undecorate(containerController: AppcuesExperienceContainerViewController) throws {
        // no-op
    }

    // MARK: AppcuesBackdropDecoratingTrait
    func decorate(backdropView: UIView) throws {
        // no-op
    }

    func undecorate(backdropView: UIView) throws {
        // no-op
    }

    // MARK: AppcuesWrapperCreatingTrait
    func createWrapper(around containerController: AppcuesExperienceContainerViewController) throws -> UIViewController {

        let error = AppcuesTraitError(description: "Error")
        _ = error.description

        return containerController
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        // no-op
    }

    // MARK: AppcuesPresentingTrait
    func present(viewController: UIViewController, completion: (() -> Void)?) throws {
        completion?()
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        completion?()
    }
}

class SampleExperienceContainerViewController: AppcuesExperienceContainerViewController {

    weak var eventHandler: AppcuesExperienceContainerEventHandler?
    let pageMonitor: AppcuesExperiencePageMonitor

    init(stepControllers: [UIViewController], pageMonitor: AppcuesExperiencePageMonitor) {
        self.pageMonitor = pageMonitor

        super.init(nibName: nil, bundle: nil)

        pageMonitor.addObserver { [weak self] newIndex, oldIndex in
            self?.eventHandler?.containerNavigated(from: oldIndex, to: newIndex)
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
        eventHandler?.containerWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        eventHandler?.containerDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        eventHandler?.containerWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        eventHandler?.containerDidDisappear()
    }
}


class SampleAction: AppcuesExperienceAction {
    static var type: String = "@sample/action"

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        // no-op
    }

    func execute(completion: @escaping () -> Void) {
        completion()
    }
}
