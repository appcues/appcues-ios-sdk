//
//  AnalyticsTrackerTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 11/22/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
import Mocker
@testable import AppcuesKit

class AnalyticsTrackerTests: XCTestCase {
    var appcues: Appcues!
    var analytics: AnalyticsTracker!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)

        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
            .urlSession(urlSession)
            .anonymousIDFactory({ "my-anonymous-id" })

        appcues = Appcues(config: config)
        appcues.container.resolve(Storage.self).userID = "my-anonymous-id" // set up initial user ID
        analytics = appcues.container.resolve(AnalyticsTracker.self)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removePersistentDomain(forName: "com.appcues.storage.00000")
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
                try requestBody.verifyMatchingProfile(["my_key": "my_value", "another_key": 33])
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        mock.register()

        appcues.container.resolve(Storage.self).userID = "specific-user-id" //simulates identify()
        let update = TrackingUpdate(type: .profile, policy: .flushThenSend, properties: ["my_key":"my_value", "another_key": 33])

        // Act
        analytics.track(update: update)

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
                try body.verifyMatchingEvents([Event(name: "eventName", attributes: ["my_key": "my_value", "another_key": 33])])
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        mock.register()

        let update = TrackingUpdate(type: .event("eventName"), policy: .queueThenFlush, properties: ["my_key":"my_value", "another_key": 33])

        // Act
        analytics.track(update: update)

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
                try body.verifyMatchingEvents([Event(pageView: "https://com.apple.dt.xctest.tool/my-test-page", attributes: ["my_key":"my_value", "another_key": 33])])
                onRequestExpectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        mock.register()

        let update = TrackingUpdate(type: .screen("My test page"), policy: .queueThenFlush, properties: ["my_key":"my_value", "another_key": 33])

        // Act
        analytics.track(update: update)

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

    func verifyMatchingProfile(_ profile: [String: Any]) throws {
        let bodyDict = try XCTUnwrap(self["profile_update"] as? [String: Any])
        try verifyPropertiesMatch(dict1: bodyDict, dict2: profile)
    }

    func verifyMatchingEvents(_ expectEvents: [Event]) throws {
        let requestEvents = try XCTUnwrap(self["events"] as? [[String: Any]])
        XCTAssertEqual(requestEvents.count, expectEvents.count)

        // Compare each event in order
        Array(zip(requestEvents, expectEvents)).forEach { requestEvent, expectEvent in
            XCTAssertEqual(requestEvent["name"] as? String, expectEvent.name)
            do {
                let bodyDict = try XCTUnwrap(requestEvent["attributes"] as? [String: Any])
                try verifyPropertiesMatch(dict1: bodyDict, dict2: expectEvent.attributes ?? [:])
            } catch {
                XCTFail(error.localizedDescription)
            }
            // Not comparing to expectEvent.date because it's fine if they're not identical
            XCTAssertNotNil(requestEvent["timestamp"] as? Int64)
        }
    }

    private func verifyPropertiesMatch(dict1: [String: Any], dict2: [String: Any]) throws {
        XCTAssertEqual(Set(dict1.keys), Set(dict2.keys))
        dict1.keys.forEach { key in
            switch(dict1[key], dict2[key]) {
            case let (val1 as String, val2 as String):
                XCTAssertEqual(val1, val2)
            case let (val1 as Int, val2 as Int):
                XCTAssertEqual(val1, val2)
            case let (val1 as Double, val2 as Double):
                XCTAssertEqual(val1, val2)
            case let (val1 as Bool, val2 as Bool):
                XCTAssertEqual(val1, val2)
            default:
                XCTFail("\(dict1[key] ?? "nil") does not match \(dict2[key] ?? "nil").")
            }
        }
    }
}
