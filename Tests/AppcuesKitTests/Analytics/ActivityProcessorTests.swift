//
//  ActivityProcessorTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 2/1/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ActivityProcessorTests: XCTestCase {

    var processor: ActivityProcessor!
    var appcues: MockAppcues!
    var mockStorage: [ActivityStorage] = []

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00000", applicationID: "abc")

        appcues = MockAppcues(config: config)
        processor = ActivityProcessor(container: appcues.container)

        mockStorage = []
        appcues.activityStorage.onSave = { activity in
            self.mockStorage.append(activity)
        }
        appcues.activityStorage.onRemove = { activity in
            self.mockStorage.removeAll { $0.requestID == activity.requestID }
        }
        appcues.activityStorage.onRead = {
            return self.mockStorage
        }
    }

    func testSyncActivityProcessed() async throws {
        // test for basic processing - standard activity is processed synchronously and POSTed to network

        // Arrange
        let onPostExpectation = expectation(description: "Activity request")
        let activity = generateMockActivity(userID: "user1", event: Event(name: "eventName", attributes: ["my_key": "my_value", "another_key": 33]))
        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
            guard case .qualify(activity.userID) = apiEndpoint else { return XCTFail() }
            try XCTUnwrap(body).verifyMatch(activity: activity)
            onPostExpectation.fulfill()
            return QualifyResponse(experiences: [.decoded(self.mockExperience)], performedQualification: true, qualificationReason: nil, experiments: nil)
        }

        // Act
        let result = try await processor.process(activity)

        XCTAssertEqual(true, result.performedQualification)
        XCTAssertEqual(1, result.experiences.count)
        XCTAssertEqual(self.mockExperience.name, result.experiences.first?.parsed.0.name)

        // Assert
        await fulfillment(of: [onPostExpectation], timeout: 1)
    }

    func testActivitySignatureCaptured() async throws {
        // test that an Activity with a userSignature gets that signature properly sent to the network call

        // Arrange
        let onPostExpectation = expectation(description: "Activity request")
        let activity = generateMockActivity(userID: "user1", event: Event(name: "eventName"), userSignature: "user-signature")
        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            guard case .bearer("user-signature") = authorization else { return XCTFail() }
            onPostExpectation.fulfill()
            return QualifyResponse(experiences: [], performedQualification: false, qualificationReason: nil, experiments: nil)
        }

        // Act
        _ = try await processor.process(activity)

        // Assert
        await fulfillment(of: [onPostExpectation], timeout: 1)
   }

    func testFailedActivityRetryNextFlush() async throws {
        // test for standard retry behavior - if an item fails to process, it is retried on the next
        // attempt to flush a new activity - the old item is retried first to maintain chronological order

        // Arrange
        let onPostExpectation1 = expectation(description: "Activity request 1")
        let onPostExpectation2 = expectation(description: "Activity request 2")
        let retryExpectation = expectation(description: "Activity retry request")
        let activity1 = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
        let activity2 = generateMockActivity(userID: "user2", event: Event(name: "event2", attributes: ["my_key": "my_value2", "another_key": 34]))
        var postCount = 0

        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            postCount += 1
            switch postCount {
            case 1:
                // first attempt we'll simulate failure
                onPostExpectation1.fulfill()
                throw URLError(.notConnectedToInternet)
            case 2:
                // this should be the retry attempt - non synchronous for activity 1
                // the callback will not be forward back to caller (happens in background retry)
                let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                guard case let .activity(userID) = apiEndpoint else {
                    XCTFail()
                    throw URLError(.unsupportedURL)
                }
                XCTAssertEqual("user1", userID)
                try XCTUnwrap(body).verifyMatch(activity: activity1)
                retryExpectation.fulfill()
                return QualifyResponse(experiences: [], performedQualification: false, qualificationReason: nil, experiments: nil)
            case 3:
                // this should be the synchronous attempt for activity 2
                let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                guard case let .qualify(userID) = apiEndpoint else {
                    XCTFail()
                    throw URLError(.unsupportedURL)
                }
                XCTAssertEqual("user2", userID)
                try XCTUnwrap(body).verifyMatch(activity: activity2)
                onPostExpectation2.fulfill()
                return QualifyResponse(experiences: [.decoded(self.mockExperience)], performedQualification: true, qualificationReason: nil, experiments: nil)
            default:
                XCTFail()
                throw URLError(.unsupportedURL)
            }
        }

        // Act
        await XCTAssertThrowsAsyncError(try await processor.process(activity1))
        let result = try await processor.process(activity2)
        XCTAssertEqual(true, result.performedQualification)
        XCTAssertEqual(1, result.experiences.count)
        XCTAssertEqual(self.mockExperience.name, result.experiences.first?.parsed.0.name)

        // Assert
        await fulfillment(of: [onPostExpectation1, retryExpectation, onPostExpectation2], timeout: 1)
    }

    func testItemsBiggerThanMaxSizeRemovedAndNotSent() async throws {
        // verify that the config value for max size is respected, and items beyond this are not retried, and get cleaned out

        // Arrange
        appcues.config.activityStorageMaxSize = 0
        let activity1 = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
        let activity2 = generateMockActivity(userID: "user2", event: Event(name: "event2", attributes: ["my_key": "my_value2", "another_key": 34]))
        var postCount = 0

        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            postCount += 1
            switch postCount {
            case 1:
                // first attempt we'll simulate failure
                throw URLError(.notConnectedToInternet)
            case 2:
                // this should be the synchronous attempt for activity 2 - no retry made
                let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                guard case let .qualify(userID) = apiEndpoint else { return XCTFail() }
                XCTAssertEqual("user2", userID)
                try XCTUnwrap(body).verifyMatch(activity: activity2)
                return QualifyResponse(experiences: [.decoded(self.mockExperience)], performedQualification: true, qualificationReason: nil, experiments: nil)
            default:
                XCTFail()
                throw URLError(.unsupportedURL)
            }
        }

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await processor.process(activity1))
        XCTAssertEqual(1, self.mockStorage.count) // failed item will stay around

        let result = try await processor.process(activity2)
        XCTAssertEqual(true, result.performedQualification)
        XCTAssertEqual(1, result.experiences.count)
        XCTAssertEqual(self.mockExperience.name, result.experiences.first?.parsed.0.name)
        XCTAssertEqual(0, self.mockStorage.count) // all cleared out
    }

    func testClientNetworkIssuesTriggerRetry() async throws {
        let networkIssues = [URLError.notConnectedToInternet, URLError.timedOut, URLError.dataNotAllowed, URLError.internationalRoamingOff]
        var currentError = URLError(networkIssues.first!)

        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            throw currentError
        }
        appcues.networking.onPostEmptyResponse = { _, _, _ in
            throw currentError
        }

        // Act
        for issue in networkIssues {
            let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
            currentError = URLError(issue)
            do {
                _ = try await processor.process(activity)
            } catch {
                if error as! URLError != currentError { XCTFail("unexpected error") }
            }
        }

        // Assert
        
        XCTAssertEqual(networkIssues.count, mockStorage.count)
    }

    func testOtherNetworkIssuesDoNotTriggerRetry() async throws {
        let networkIssues = [URLError.badServerResponse, URLError.unknown, URLError.userAuthenticationRequired, URLError.httpTooManyRedirects]
        var currentError = URLError(networkIssues.first!)

        appcues.networking.onPostEmptyResponse = { _, _, _ in
            throw currentError
        }
        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            throw currentError
        }

        // Act
        for issue in networkIssues {
            let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
            currentError = URLError(issue)
            do {
                _ = try await processor.process(activity)
            } catch {
                if error as! URLError != currentError { XCTFail("unexpected error") }
            }
        }

        // Assert
        XCTAssertEqual(0, mockStorage.count)
    }

    func testItemsOlderThanMaxAgeRemovedAndNotSent() async throws {
        // verify that the config value for max age is respected, and items beyond this are not retried, and get cleaned out

        // Arrange
        appcues.config.activityStorageMaxAge = 1
        let activity1 = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
        let activity2 = generateMockActivity(userID: "user2", event: Event(name: "event2", attributes: ["my_key": "my_value2", "another_key": 34]))
        var postCount = 0

        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            postCount += 1
            switch postCount {
            case 1:
                // first attempt we'll simulate failure
                throw URLError(.notConnectedToInternet)
            case 2:
                // this should be the synchronous attempt for activity 2 - no retry made
                let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                guard case let .qualify(userID) = apiEndpoint else { return XCTFail() }
                XCTAssertEqual("user2", userID)
                try XCTUnwrap(body).verifyMatch(activity: activity2)
                return QualifyResponse(experiences: [.decoded(self.mockExperience)], performedQualification: true, qualificationReason: nil, experiments: nil)
            default:
                XCTFail()
                throw URLError(.unsupportedURL)
            }
        }

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await processor.process(activity1))
        XCTAssertEqual(1, self.mockStorage.count) // failed item will stay around

        try await Task.sleep(nanoseconds: 1_000_000_000 * 2)

        let result = try await processor.process(activity2)
        XCTAssertEqual(true, result.performedQualification)
        XCTAssertEqual(1, result.experiences.count)
        XCTAssertEqual(self.mockExperience.name, result.experiences.first?.parsed.0.name)
        XCTAssertEqual(0, self.mockStorage.count) // all cleared out
    }

    func testActivitySentIfStorageSizeZero() async throws {
        // ensure even if config option used to disable all storage/retry - the current item being processed is still sent

        // Arrange
        appcues.config.activityStorageMaxSize = 0
        let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))

        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            return QualifyResponse(experiences: [.decoded(self.mockExperience)], performedQualification: true, qualificationReason: nil, experiments: nil)
        }

        // Act
        let result = try await processor.process(activity)

        // Assert
        XCTAssertNotNil(result)
    }

    func testThreadSafety() throws {
        // Arrange
        let dispatchGroup = DispatchGroup()
        let completeExpectation = expectation(description: "multi thread")
        completeExpectation.expectedFulfillmentCount = 100
        let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))

        appcues.networking.onPost = { endpoint, authorization, body, requestId in
            return QualifyResponse(experiences: [], performedQualification: false, qualificationReason: nil, experiments: nil)
        }

        // Act
        // Process activity on 100 threads
        for _ in 0..<100 {
            dispatchGroup.enter()
            Task.detached {
                _ = try await self.processor.process(activity)
                completeExpectation.fulfill()
                dispatchGroup.leave()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    private func generateMockActivity(userID: String, event: Event, userSignature: String? = nil) -> Activity {
        return Activity(
            accountID: "00000",
            appID: "abc",
            sessionID: UUID().appcuesFormatted,
            userID: userID,
            events: [event],
            profileUpdate: nil,
            groupID: nil,
            groupUpdate: nil,
            userSignature: userSignature
        )
    }

    private let mockExperience = Experience(id: UUID(), name: "test_experience", type: "mobile", publishedAt: 1632142800000, context: nil, traits: [], steps: [], redirectURL: nil, nextContentID: nil, renderContext: .modal)

}

extension XCTestCase {

    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting")
        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpectation.fulfill()

        }
        // We use a buffer here to avoid flakiness with Timer on CI
        wait(for: [waitExpectation], timeout: duration + 0.5)
    }
}

private extension Data {
    // Xcode 15+ can no longer compare `body` Data to and Activity as Data instances directly, even if same
    // contents, they may not pass an equality check, so comparing data values within instead
    func verifyMatch(activity: Activity) throws {
        let bodyJson = try JSONSerialization.jsonObject(with: self, options: []) as? [String : Any]
        let unwrappedBodyJson = try XCTUnwrap(bodyJson)
        XCTAssertEqual(activity.userID, unwrappedBodyJson["user_id"] as? String)
        XCTAssertEqual(activity.sessionID, unwrappedBodyJson["session_id"] as? String)
        XCTAssertEqual(activity.requestID.appcuesFormatted, unwrappedBodyJson["request_id"] as? String)
        XCTAssertEqual(activity.accountID, unwrappedBodyJson["account_id"] as? String)
        XCTAssertEqual(activity.groupID, unwrappedBodyJson["group_id"] as? String)
        let events = unwrappedBodyJson["events"] as? [[String : Any]]
        let unwrappedEvents = try XCTUnwrap(events)
        XCTAssertEqual(activity.events?.count, unwrappedEvents.count)
        try unwrappedEvents.enumerated().forEach { index, event in
            let expectedEvent = try XCTUnwrap(activity.events?[index])
            XCTAssertEqual(expectedEvent.name, event["name"] as? String)
            let expectedAttributes = try XCTUnwrap(expectedEvent.attributes)
            expectedAttributes.verifyPropertiesMatch(event["attributes"] as? [String : Any])
        }
    }
}
