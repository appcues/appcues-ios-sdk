//
//  AppcuesTests.swift
//  AppcuesTests
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
import Mocker
@testable import AppcuesKit

class AppcuesTests: XCTestCase {
    var instance: Appcues!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)

        let config = Appcues.Config(accountID: "00000")
            .urlSession(urlSession)
            .anonymousIDFactory({ "my-anonymous-id" })

        instance = Appcues(config: config)
    }

    override func tearDownWithError() throws {
    }

    func testIdentifyRequestBody() throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        var mock = try XCTUnwrap(Mock.emptyResponse(for: "https://api.appcues.com/v1/accounts/00000/users/specific-user-id/activity?sync=1"))
        mock.onRequest = { request, postBodyArguments in
            // Assert (do/catch necessary because the closure is non-throwing)
            do {
                let requestBody = try XCTUnwrap(postBodyArguments)
                try requestBody.verifyRequestID()
                try requestBody.verifyMatchingProfile(["my_key": "my_value"])
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        mock.register()

        // Act
        instance.identify(userID: "specific-user-id", properties: ["my_key":"my_value"])

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testTrackEventRequestBody() throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        var mock = try XCTUnwrap(Mock.emptyResponse(for: "https://api.appcues.com/v1/accounts/00000/users/my-anonymous-id/activity?sync=1"))
        mock.onRequest = { request, postBodyArguments in
            // Assert (do/catch necessary because the closure is non-throwing)
            do {
                let body = try XCTUnwrap(postBodyArguments)
                try body.verifyRequestID()
                try body.verifyMatchingEvents([Event(name: "eventName", attributes: ["my_key": "my_value"])])
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        mock.register()

        // Act
        instance.track(name: "eventName", properties: ["my_key":"my_value"])

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testTrackScreenRequestBody() throws {
        // Arrange
        let onRequestExpectation = expectation(description: "Valid request")

        var mock = try XCTUnwrap(Mock.emptyResponse(for: "https://api.appcues.com/v1/accounts/00000/users/my-anonymous-id/activity?sync=1"))
        mock.onRequest = { request, postBodyArguments in
            // Assert (do/catch necessary because the closure is non-throwing)
            do {
                let body = try XCTUnwrap(postBodyArguments)
                try body.verifyRequestID()
                try body.verifyMatchingEvents([Event(pageView: "https://com.apple.dt.xctest.tool/my-test-page", attributes: ["my_key":"my_value"])])
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        mock.register()

        // Act
        instance.screen(title: "My test page", properties: ["my_key":"my_value"])

        // Assert
        waitForExpectations(timeout: 1)
    }
}

// Helpers for repeatetd Mock setup
private extension Mock {
    static let emptyResponse = #"{ "contents": [], "performed_qualification": true }"#

    static func emptyResponse(for urlString: String) throws -> Mock {
        Mock(
            url: try XCTUnwrap(URL(string: urlString)),
            dataType: .json,
            statusCode: 200,
            data: [
                .post : try XCTUnwrap(Mock.emptyResponse.data(using: .utf8))
            ])
    }
}

// Helpers to test an Activity request body is as expected
private extension Dictionary where Key == String, Value == Any {
    func verifyRequestID() throws {
        let requestID = try XCTUnwrap(self["request_id"] as? String)
        XCTAssertNotNil(UUID(uuidString: requestID), "request ID is a valid UUID")
    }

    func verifyMatchingProfile(_ profile: [String: String]) throws {
        XCTAssertEqual(self["profile_update"] as? [String: String], profile)
    }

    func verifyMatchingEvents(_ expectEvents: [Event]) throws {
        let requestEvents = try XCTUnwrap(self["events"] as? [[String: Any]])
        XCTAssertEqual(requestEvents.count, expectEvents.count)

        // Compare each event in order
        Array(zip(requestEvents, expectEvents)).forEach { requestEvent, expectEvent in
            XCTAssertEqual(requestEvent["name"] as? String, expectEvent.name)
            XCTAssertEqual(requestEvent["attributes"] as? [String: String], expectEvent.attributes)
            // Not comparing to expectEvent.date because it's fine if they're not identical
            XCTAssertNotNil(requestEvent["timestamp"] as? String)
        }
    }
}
