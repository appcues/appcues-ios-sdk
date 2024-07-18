//
//  AppcuesLinkActionTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-01-20.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
import SafariServices
@testable import AppcuesKit

@available(iOS 13.0, *)
class AppcuesLinkActionTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    func testInit() throws {
        // Act)
        let action = AppcuesLinkAction(configuration: AppcuesExperiencePluginConfiguration(AppcuesLinkAction.Config(url: URL(string: "https://appcues.com")!, openExternally: nil), appcues: appcues))
        let failedAction = AppcuesLinkAction(appcues: appcues)

        // Assert
        XCTAssertEqual(AppcuesLinkAction.type, "@appcues/link")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.url.absoluteString, "https://appcues.com")
        XCTAssertEqual(action?.openExternally, false)
        XCTAssertNil(failedAction)
    }

    func testInternalInit() throws {
        let action = AppcuesLinkAction(appcues: appcues, url: URL(string: "https://appcues.com")!, openExternally: true)

        XCTAssertEqual(action.url.absoluteString, "https://appcues.com")
        XCTAssertTrue(action.openExternally)
    }

    func testExecuteWebLink() throws {
        // Arrange
        var completionCount = 0
        var presentCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onPresent = { vc in
            XCTAssertTrue(vc is SFSafariViewController)
            presentCount += 1
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: false)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(presentCount, 1)
    }

    func testExecuteExternalWebLink() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCount += 1
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: true)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteSchemeLink() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "deeplink://test")
            openCount += 1
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "deeplink://test", openExternally: false)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1, "A non http(s) link must always open externally, even if that means overriding the config")
    }

    func testExecuteUniversalLink() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onUniversalOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCount += 1
            return true
        }
        mockURLOpener.onOpen = { url in
            XCTFail("Shouldn't be called since the URL should be handled by the universal link")
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: true)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteUniversalLinkDisabled() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onUniversalOpen = { url in
            XCTFail("Shouldn't be called since universal link handling is disabled")
            return false
        }
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCount += 1
        }
        let config = Appcues.Config(accountID: "00000", applicationID: "abc").enableUniversalLinks(false)
        let appcuesDisabledUniversalLinks = MockAppcues(config: config)
        let action = AppcuesLinkAction(appcues: appcuesDisabledUniversalLinks, path: "https://appcues.com", openExternally: true)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteUniversalLinkAllowList() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.universalLinkHostAllowList = ["appcues.com"]
        mockURLOpener.onUniversalOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCount += 1
            return true
        }
        mockURLOpener.onOpen = { url in
            XCTFail("Shouldn't be called since the URL should be handled by the universal link")
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: true)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteUniversalLinkNotOnAllowList() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.universalLinkHostAllowList = ["myapp.com"]
        mockURLOpener.onUniversalOpen = { url in
            XCTFail("Shouldn't be handled as a universal link")
            return true
        }
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCount += 1
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: true)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }


    func testExecuteWebLinkWithNavigationDelegate() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockNavigationDelegate = MockNavigationDelegate()
        mockNavigationDelegate.onNavigate = { url, openExternally in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            XCTAssertTrue(openExternally)
            openCount += 1
        }
        appcues.navigationDelegate = mockNavigationDelegate

        let mockURLOpener = MockURLOpener()
        mockURLOpener.onUniversalOpen = { url in
            XCTFail("Shouldn't be called since the URL should be handled by the navigation delegate")
            return false
        }
        mockURLOpener.onOpen = { url in
            XCTFail("Shouldn't be called since the URL should be handled by the navigation delegate")
        }

        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: true)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteSchemeLinkWithNavigationDelegate() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockNavigationDelegate = MockNavigationDelegate()
        mockNavigationDelegate.onNavigate = { url, openExternally in
            XCTAssertEqual(url.absoluteString, "deeplink://test")
            XCTAssertFalse(openExternally)
            openCount += 1
        }
        appcues.navigationDelegate = mockNavigationDelegate

        let mockURLOpener = MockURLOpener()
        mockURLOpener.onUniversalOpen = { url in
            XCTFail("Shouldn't be called since the URL should be handled by the navigation delegate")
            return false
        }
        mockURLOpener.onOpen = { url in
            XCTFail("Shouldn't be called since the URL should be handled by the navigation delegate")
        }

        let action = AppcuesLinkAction(appcues: appcues, path: "deeplink://test", openExternally: false)
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteCompletesWithoutAppcuesInstance() throws {
        // Arrange
        var completionCount = 0
        let action = try XCTUnwrap(AppcuesLinkAction(appcues: nil, path: "https://appcues.com"))

        // Act
        action.execute(completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
    }
}

private class MockNavigationDelegate: AppcuesNavigationDelegate {
    var onNavigate: ((URL, Bool) -> Void)?
    func navigate(to url: URL, openExternally: Bool, completion: @escaping (Bool) -> Void) {
        onNavigate?(url, openExternally)
        completion(true)
    }
}

@available(iOS 13.0, *)
extension AppcuesLinkActionTests {
    class MockURLOpener: TopControllerGetting, URLOpening {
        var hasActiveWindowScenes: Bool = true

        var universalLinkHostAllowList: [String]?

        var onOpen: ((URL) -> Void)?
        func open(_ url: URL, completionHandler: @escaping (() -> Void)) {
            onOpen?(url)
            completionHandler()
        }

        var onUniversalOpen: ((URL) -> Bool)?
        func open(potentialUniversalLink: URL) -> Bool {
            onUniversalOpen?(potentialUniversalLink) ?? false
        }

        var onPresent: ((UIViewController) -> Void)?
        func topViewController() -> UIViewController? {
            let topVC = MockVC()
            topVC.onPresent = onPresent
            return topVC
        }
    }

    class MockVC: UIViewController {
        var onPresent: ((UIViewController) -> Void)?

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            onPresent?(viewControllerToPresent)
            completion?()
            super.present(viewControllerToPresent, animated: flag)
        }
    }
}

@available(iOS 13.0, *)
extension AppcuesLinkAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, path: String, openExternally: Bool? = nil) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesLinkAction.Config(url: URL(string: path)!, openExternally: openExternally), appcues: appcues))
    }
}
