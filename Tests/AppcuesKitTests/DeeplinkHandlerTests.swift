//
//  DeeplinkHandlerTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class DeeplinkHandlerTests: XCTestCase {

    var appcues: MockAppcues!
    var deeplinkHandler: DeeplinkHandler!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        deeplinkHandler = DeeplinkHandler(container: appcues.container)
    }

    func testActionInits() throws {
        XCTAssertNotNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNotNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNotNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_content/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/experience_content/f0edab83-5257-47a5-81fc-80389d14905b")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNotNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/debugger")!, isSessionActive: true, applicationID: "abc"))
        XCTAssertNotNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/debugger")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/bad-path")!, isSessionActive: false, applicationID: "abc"))
        XCTAssertNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://missing-host")!, isSessionActive: false, applicationID: "abc"))
        XCTAssertNil(DeeplinkHandler.Action(url: URL(string: "scheme://sdk/debugger")!, isSessionActive: false, applicationID: "abc"))

        XCTAssertNil(DeeplinkHandler.Action(url: URL(string: "appcues-abc://sdk/different-appid")!, isSessionActive: false, applicationID: "xyz"))
    }

    func testHandlePreviewURLWithActiveScene() throws {
        // Arrange
        deeplinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/experience_preview/f0edab83-5257-47a5-81fc-80389d14905b"))

        var loaderCalled = false
        appcues.experienceLoader.onLoad = { id, published, completion in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertFalse(published)
            loaderCalled = true
            completion?(.success(()))
        }

        // Act
        let handled = deeplinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(loaderCalled)
    }

    func testHandleContentURLWithInactiveScene() throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/experience_content/f0edab83-5257-47a5-81fc-80389d14905b"))

        var loaderCalled = false
        appcues.experienceLoader.onLoad = { id, published, completion in
            XCTAssertEqual(id, "f0edab83-5257-47a5-81fc-80389d14905b")
            XCTAssertTrue(published)
            loaderCalled = true
            completion?(.success(()))
        }

        // Act
        let handled = deeplinkHandler.didHandleURL(url)
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(loaderCalled)
    }

    func testHandleDebugURLWithActiveScene() throws {
        // Arrange
        deeplinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/debugger"))

        var debuggerShown = false
        appcues.debugger.onShow = { destination in
            XCTAssertNil(destination)
            debuggerShown = true
        }

        // Act
        let handled = deeplinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(debuggerShown)
    }

    func testHandleDebugURLWithActiveSceneAndDestination() throws {
        // Arrange
        deeplinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "appcues-abc://sdk/debugger/fonts"))

        var debuggerShown = false
        appcues.debugger.onShow = { destination in
            XCTAssertEqual(destination, DebugDestination.fonts)
            debuggerShown = true
        }

        // Act
        let handled = deeplinkHandler.didHandleURL(url)

        // Assert
        XCTAssertTrue(handled)
        XCTAssertTrue(debuggerShown)
    }
    func testHandleNonAppcuesURL() throws {
        // Arrange
        deeplinkHandler.topControllerGetting = MockTopControllerGetting()
        let url = try XCTUnwrap(URL(string: "my-app://profile"))

        // Act
        let handled = deeplinkHandler.didHandleURL(url)

        // Assert
        XCTAssertFalse(handled)
    }
}

@available(iOS 13.0, *)
extension DeeplinkHandlerTests {
    class MockTopControllerGetting: TopControllerGetting {
        func topViewController() -> UIViewController? {
            UIViewController()
        }
    }
}
