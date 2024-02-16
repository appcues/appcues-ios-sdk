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
            .settingsHost(URL(string: "localhost")!)
            .sessionTimeout(3600)
            .activityStorageMaxSize(25)
            .activityStorageMaxAge(3600)
            .urlSession(URLSession.shared)
            .anonymousIDFactory({ UUID().uuidString })
            .additionalAutoProperties(["test": "value"])
            .enableUniversalLinks(true)
            .enableTextScaling(true)
            .enableStepRecoveryObserver(true)

        let appcuesInstance = Appcues(config: config)

        let presentationDelegate = SamplePresentationDelegate()
        appcuesInstance.presentationDelegate = presentationDelegate

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

        appcuesInstance.setPushToken(nil)

        appcuesInstance.debug()

        appcuesInstance.trackScreens()

        _ = appcuesInstance.didHandleURL(URL(string: "https://api.appcues.net")!)

        if #available(iOS 13.0, *) {
            _ = appcuesInstance.filterAndHandle(Set())
        }

        let frameView = AppcuesFrameView(frame: .zero)
        appcuesInstance.register(frameID: "frame1", for: frameView, on: UIViewController())
        frameView.presentationDelegate = presentationDelegate

        if #available(iOS 13.0, *) {
            let frame = AppcuesFrame(appcues: appcuesInstance, frameID: "frame1")
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

class SamplePresentationDelegate: AppcuesPresentationDelegate {
    func canDisplayExperience(metadata: AppcuesPresentationMetadata) -> Bool {
        true
    }
    
    func experienceWillAppear(metadata: AppcuesPresentationMetadata) {
        let id = metadata.id
        let name = metadata.name
        let isOverlay = metadata.isOverlay
        let isEmbed = metadata.isEmbed
        let frameID = metadata.frameID
    }
    
    func experienceDidAppear(metadata: AppcuesPresentationMetadata) {
        // no-op
    }

    func experienceStepDidChange(metadata: AppcuesPresentationMetadata) {
        // no-op
    }

    func experienceWillDisappear(metadata: AppcuesPresentationMetadata) {
        // no-op
    }
    
    func experienceDidDisappear(metadata: AppcuesPresentationMetadata) {
        // no-op
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
