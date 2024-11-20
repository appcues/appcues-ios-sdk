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

    func testExecuteWebLink() async throws {
        // Arrange
        var presentCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onPresent = { vc in
            XCTAssertTrue(vc is SFSafariViewController)
            presentCount += 1
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: false)
        action?.urlOpener = mockURLOpener

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(presentCount, 1)
    }

    func testExecuteExternalWebLink() async throws {
        // Arrange
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCount += 1
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "https://appcues.com", openExternally: true)
        action?.urlOpener = mockURLOpener

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteSchemeLink() async throws {
        // Arrange
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "deeplink://test")
            openCount += 1
        }
        let action = AppcuesLinkAction(appcues: appcues, path: "deeplink://test", openExternally: false)
        action?.urlOpener = mockURLOpener

        // Act
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1, "A non http(s) link must always open externally, even if that means overriding the config")
    }

    func testExecuteUniversalLink() async throws {
        // Arrange
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
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteUniversalLinkDisabled() async throws {
        // Arrange
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
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteUniversalLinkAllowList() async throws {
        // Arrange
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
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteUniversalLinkNotOnAllowList() async throws {
        // Arrange
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
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1)
    }


    func testExecuteWebLinkWithNavigationDelegate() async throws {
        // Arrange
        var openCount = 0
        let mockNavigationDelegate = MockNavigationDelegate()
        mockNavigationDelegate.onNavigate = { url, openExternally in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            XCTAssertTrue(openExternally)
            openCount += 1
            return true
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
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteSchemeLinkWithNavigationDelegate() async throws {
        // Arrange
        var openCount = 0
        let mockNavigationDelegate = MockNavigationDelegate()
        mockNavigationDelegate.onNavigate = { url, openExternally in
            XCTAssertEqual(url.absoluteString, "deeplink://test")
            XCTAssertFalse(openExternally)
            openCount += 1
            return true
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
        try await action?.execute()

        // Assert
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteThrowsWithoutAppcuesInstance() async throws {
        // Arrange
        let action = try XCTUnwrap(AppcuesLinkAction(appcues: nil, path: "https://appcues.com"))

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await action.execute()) {
            XCTAssertEqual(($0 as? AppcuesTraitError)?.description, "No appcues instance")
        }
    }
}

private class MockNavigationDelegate: AppcuesNavigationDelegate {

    var onNavigate: ((URL, Bool) -> Bool)?
    func navigate(to url: URL, openExternally: Bool) async -> Bool {
        onNavigate?(url, openExternally) ?? false
    }
}

extension AppcuesLinkActionTests {
    class MockURLOpener: TopControllerGetting, URLOpening {
        var hasActiveWindowScenes: Bool = true

        var universalLinkHostAllowList: [String]?

        var onOpen: ((URL) -> Void)?
        func open(_ url: URL) async {
            onOpen?(url)
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

extension AppcuesLinkAction {
    convenience init?(appcues: Appcues?) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(nil, appcues: appcues))
    }
    convenience init?(appcues: Appcues?, path: String, openExternally: Bool? = nil) {
        self.init(configuration: AppcuesExperiencePluginConfiguration(AppcuesLinkAction.Config(url: URL(string: path)!, openExternally: openExternally), appcues: appcues))
    }
}
