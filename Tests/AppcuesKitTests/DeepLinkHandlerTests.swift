//
//  DeepLinkHandlerTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
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

        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/debugger")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/debugger")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/bad-path")!, isSessionActive: false, applicationID: "abc"))
        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://missing-host")!, isSessionActive: false, applicationID: "abc"))
        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "scheme://sdk/debugger")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNil(DeepLinkHandler.Action(url: URL(string: "appcues-abc://sdk/different-appid")!, isSessionActive: false, applicationID: "xyz"))

        XCTAssertNotNil(DeepLinkHandler.Action(url: URL(string: "appcues-democues://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
    }

    func testHandlePreviewURLWithActiveScene() throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b"))

        var loaderCalled = false
        appcues.experienceLoader.onLoad = { id, published, trigger, completion in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertFalse(published)
            guard case .preview = trigger else { return XCTFail() }
            loaderCalled = true
            completion?(.success(()))
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(loaderCalled)
    }

    func testHandleContentURLWithInactiveScene() throws {
        // Arrange
        appcues.sessionID = UUID()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/experience_content/f0edab83-5257-47a5-81fc-80389d14905b"))

        var loaderCalled = false
        appcues.experienceLoader.onLoad = { id, published, trigger, completion in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertTrue(published)
            guard case .deepLink = trigger else { return XCTFail() }
            loaderCalled = true
            completion?(.success(()))
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(loaderCalled)
    }

    func testHandleDebugURLWithActiveScene() throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/debugger"))

        var debuggerShown = false
        appcues.debugger.onShow = { destination in
            XCTAssertNil(destination)
            debuggerShown = true
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(debuggerShown)
    }

    func testHandleDebugURLWithActiveSceneAndDestination() throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/debugger/fonts"))

        var debuggerShown = false
        appcues.debugger.onShow = { destination in
            XCTAssertEqual(destination, DebugDestination.fonts)
            debuggerShown = true
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(debuggerShown)
    }

    func testHandleDebugDeepLinkVerification() throws {
        // Arrange
        deepLinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/verify/token-123"))

        var debuggerVerificationCalled = false
        appcues.debugger.onVerify = { token in
            XCTAssertEqual(token, "token-123")
            debuggerVerificationCalled = true
        }

        // Act
        let handled = deepLinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(debuggerVerificationCalled)
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

@available(iOS 13.0, *)
extension DeepLinkHandlerTests {
    class MockTopControllerGetting: TopControllerGetting {
        func topViewController() -> UIViewController? {
            UIViewController()
        }
    }
}
