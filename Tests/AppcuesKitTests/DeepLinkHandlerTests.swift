//
//  DeepLinkHandlerTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class DeepLinkHandlerTests: XCTestCase {

    var appcues: MockAppcues!
    var deepLinkHandler: DeepLinkHandler!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        deepLinkHandler = DeepLinkHandler(container: appcues.container)
    }

    func testActionInits() throws {
        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_content/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_content/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/push_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/push_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/push_content/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/push_content/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/debugger")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/debugger")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/bad-path")!, isSessionActive: false, applicationID: "abc"))
        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://missing-host")!, isSessionActive: false, applicationID: "abc"))
        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "scheme://sdk/debugger")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/different-appid")!, isSessionActive: false, applicationID: "xyz"))

        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-democues://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
    }

    func testHandlePreviewFailToast() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/experience_preview/invalid-id"))

        let loaderExpectation = expectation(description: "Loader called")
        appcues.contentLoader.onLoad = { id, published, trigger in
            XCTAssertEqual(id, "invalid-id")
            XCTAssertFalse(published)
            guard case .preview = trigger else { return XCTFail() }
            loaderExpectation.fulfill()
            throw NetworkingError.nonSuccessfulStatusCode(404, nil)
        }

        let toastExpectation = expectation(description: "Toast shown")
        appcues.debugger.onShowToast = { toast in
            XCTAssertEqual(toast.style, .failure)
            toastExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [loaderExpectation, toastExpectation], timeout: 1, enforceOrder: true)
    }

    func testHandlePreviewURLWithActiveScene() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b"))

        let loaderExpectation = expectation(description: "Loader called")
        appcues.contentLoader.onLoad = { id, published, trigger in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertFalse(published)
            guard case .preview = trigger else { return XCTFail() }
            loaderExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [loaderExpectation], timeout: 1)
    }

    func testHandleContentURLWithInactiveScene() async throws {
        // Arrange
        appcues.sessionID = UUID()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/experience_content/f0edab83-5257-47a5-81fc-80389d14905b"))

        let loaderExpectation = expectation(description: "Loaded called")
        appcues.contentLoader.onLoad = { id, published, trigger in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertTrue(published)
            guard case .deepLink = trigger else { return XCTFail() }
            loaderExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)
        // Xcode 15 requires `await`
        await NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [loaderExpectation], timeout: 2)
    }

    func testHandlePushPreview() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/push_preview/f0edab83-5257-47a5-81fc-80389d14905b?key=value"))

        let loaderExpectation = expectation(description: "Loaded called")
        appcues.contentLoader.onLoadPush = { id, published, queryItems in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertEqual(queryItems, [URLQueryItem(name: "key", value: "value")])
            XCTAssertFalse(published)
            loaderExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [loaderExpectation], timeout: 1)
    }

    func testHandlePushContent() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/push_content/f0edab83-5257-47a5-81fc-80389d14905b"))

        let loaderExpectation = expectation(description: "Loaded called")
        appcues.contentLoader.onLoadPush = { id, published, queryItems in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertEqual(queryItems.count, 0)
            XCTAssertTrue(published)
            loaderExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [loaderExpectation], timeout: 1)
    }

    func testHandleDebugURLWithActiveScene() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/debugger"))

        let debuggerExpectation = expectation(description: "Debugger shown")
        appcues.debugger.onShow = { mode in
            guard case let .debugger(destination) = mode else { return XCTFail() }
            XCTAssertNil(destination)
            debuggerExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [debuggerExpectation], timeout: 1)
    }

    func testHandleDebugURLWithActiveSceneAndDestination() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/debugger/fonts"))

        let debuggerExpectation = expectation(description: "Debugger shown")
        appcues.debugger.onShow = { mode in
            guard case let .debugger(destination) = mode else { return XCTFail() }
            XCTAssertEqual(destination, DebugDestination.fonts)
            debuggerExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [debuggerExpectation], timeout: 1)
    }

    func testHandleScreenCapture() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/capture_screen?token=123"))

        let debuggerExpectation = expectation(description: "Debugger shown")
        appcues.debugger.onShow = { mode in
            guard case .screenCapture = mode else { return XCTFail() }
            debuggerExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [debuggerExpectation], timeout: 1)
    }

    func testHandleDebugDeepLinkVerification() async throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/verify/token-123"))

        let debuggerExpectation = expectation(description: "Debugger verification called")
        appcues.debugger.onVerify = { token in
            XCTAssertEqual(token, "token-123")
            debuggerExpectation.fulfill()
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        await fulfillment(of: [debuggerExpectation], timeout: 1)
    }

    func testHandleNonAppcuesURL() throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "my-app://profile"))

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertFalse(handled)
    }
}

extension DeepLinkHandlerTests {
    class MockTopControllerGetting: TopControllerGetting {
        var hasActiveWindowScenes: Bool = true

        func topViewController() -> UIViewController? {
            UIViewController()
        }
    }
}
