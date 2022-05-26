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
        // Act
        let action = AppcuesLinkAction(config: ["url": "https://appcues.com"])
        let failedAction = AppcuesLinkAction(config: [:])

        // Assert
        XCTAssertEqual(AppcuesLinkAction.type, "@appcues/link")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.url.absoluteString, "https://appcues.com")
        XCTAssertEqual(action?.openExternally, false)
        XCTAssertNil(failedAction)
    }

    func testExecute() throws {
        // Arrange
        var completionCount = 0
        var presentCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onPresent = { vc in
            XCTAssertTrue(vc is SFSafariViewController)
            presentCount += 1
        }
        let action = AppcuesLinkAction(config: ["url": "https://appcues.com", "openExternally": false])
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(presentCount, 1)
    }

    func testExecuteExternal() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCount += 1
        }
        let action = AppcuesLinkAction(config: ["url": "https://appcues.com", "openExternally": true])
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1)
    }

    func testExecuteNonWebURL() throws {
        // Arrange
        var completionCount = 0
        var openCount = 0
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "deeplink://test")
            openCount += 1
        }
        let action = AppcuesLinkAction(config: ["url": "deeplink://test", "openExternally": false])
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(inContext: appcues, completion: { completionCount += 1 })

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(openCount, 1, "A non http(s) link must always open externally, even if that means overriding the config")
    }
}

@available(iOS 13.0, *)
extension AppcuesLinkActionTests {
    class MockURLOpener: TopControllerGetting, URLOpening {
        var onOpen: ((URL) -> Void)?
        var onPresent: ((UIViewController) -> Void)?

        func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler: ((Bool) -> Void)?) {
            onOpen?(url)
            completionHandler?(true)
        }

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
