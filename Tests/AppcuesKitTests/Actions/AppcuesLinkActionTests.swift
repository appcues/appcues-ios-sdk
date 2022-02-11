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
        var presentCalled = false
        let completionExpectation = expectation(description: "action completed")
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onPresent = { vc in
            XCTAssertTrue(vc is SFSafariViewController)
            presentCalled = true
        }
        var action = AppcuesLinkAction(config: ["url": "https://appcues.com", "external": false])
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(inContext: appcues) {
            completionExpectation.fulfill()
        }

        // Assert
        XCTAssertTrue(presentCalled)
        waitForExpectations(timeout: 1)
    }

    func testExecuteExternal() throws {
        // Arrange
        var openCalled = false
        let completionExpectation = expectation(description: "action completed")
        let mockURLOpener = MockURLOpener()
        mockURLOpener.onOpen = { url in
            XCTAssertEqual(url.absoluteString, "https://appcues.com")
            openCalled = true
        }
        var action = AppcuesLinkAction(config: ["url": "https://appcues.com", "external": true])
        action?.urlOpener = mockURLOpener

        // Act
        action?.execute(inContext: appcues) {
            completionExpectation.fulfill()
        }

        // Assert
        XCTAssertTrue(openCalled)
        waitForExpectations(timeout: 1)
    }
}

extension AppcuesLinkActionTests {
    class MockURLOpener: URLOpening {
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
            super.present(viewControllerToPresent, animated: flag, completion: nil)
        }
    }
}
