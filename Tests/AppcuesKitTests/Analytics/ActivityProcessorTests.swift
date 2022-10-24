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

    func testSyncActivityProcessed() throws {
        // test for basic processing - standard activity is processed synchronously and POSTed to network

        // Arrange
        let onPostExpectation = expectation(description: "Activity request")
        let resultCallbackExpectation = expectation(description: "Process result")
        let activity = generateMockActivity(userID: "user1", event: Event(name: "eventName", attributes: ["my_key": "my_value", "another_key": 33]))
        appcues.networking.onPost = { endpoint, body, completion in
            do {
                let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                guard case .qualify(activity.userID) = apiEndpoint else { return XCTFail() }
                let data = try NetworkClient.encoder.encode(activity)
                XCTAssertEqual(data, body)
                onPostExpectation.fulfill()
                completion(.success(QualifyResponse(experiences: [self.mockExperience], performedQualification: true, qualificationReason: nil)))
            } catch {
                XCTFail()
            }
        }

        // Act
        processor.process(activity) { result in
            guard case let .success(taco) = result else { return XCTFail() }
            XCTAssertEqual(true, taco.performedQualification)
            XCTAssertEqual(1, taco.experiences.count)
            XCTAssertEqual(self.mockExperience.name, taco.experiences.first?.name)
            resultCallbackExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testFailedActivityRetryNextFlush() throws {
        // test for standard retry behavior - if an item fails to process, it is retried on the next
        // attempt to flush a new activity - the old item is retried first to maintain chronological order

        // Arrange
        let onPostExpectation1 = expectation(description: "Activity request 1")
        let onPostExpectation2 = expectation(description: "Activity request 2")
        let retryExpectation = expectation(description: "Activity retry request")
        let resultCallbackExpectation1 = expectation(description: "Process result 1")
        let resultCallbackExpectation2 = expectation(description: "Process result 2")
        let activity1 = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
        let activity2 = generateMockActivity(userID: "user2", event: Event(name: "event2", attributes: ["my_key": "my_value2", "another_key": 34]))
        var postCount = 0

        appcues.networking.onPost = { endpoint, body, completion in
            do {
                postCount += 1
                if postCount == 1 {
                    // first attempt we'll simulate failure
                    completion(.failure(URLError(URLError.notConnectedToInternet)))
                    onPostExpectation1.fulfill()
                } else if postCount == 2 {
                    // this should be the retry attempt - non synchronous for activity 1
                    // the callback will not be forward back to caller (happens in background retry)
                    let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                    guard case let .activity(userID) = apiEndpoint else { return XCTFail() }
                    XCTAssertEqual("user1", userID)
                    let data = try NetworkClient.encoder.encode(activity1)
                    XCTAssertEqual(data, body)
                    completion(.success(QualifyResponse(experiences: [], performedQualification: false, qualificationReason: nil)))
                    retryExpectation.fulfill()
                } else if postCount == 3 {
                    // this should be the synchronous attempt for activity 2
                    let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                    guard case let .qualify(userID) = apiEndpoint else { return XCTFail() }
                    XCTAssertEqual("user2", userID)
                    let data = try NetworkClient.encoder.encode(activity2)
                    XCTAssertEqual(data, body)
                    completion(.success(QualifyResponse(experiences: [self.mockExperience], performedQualification: true, qualificationReason: nil)))
                    onPostExpectation2.fulfill()
                } else {
                    XCTFail()
                }
            } catch {
                XCTFail()
            }
        }

        // Act
        processor.process(activity1) { result in
            guard case .failure = result else { return XCTFail() }
            resultCallbackExpectation1.fulfill()
        }
        processor.process(activity2) { result in
            guard case let .success(taco) = result else { return XCTFail() }
            XCTAssertEqual(true, taco.performedQualification)
            XCTAssertEqual(1, taco.experiences.count)
            XCTAssertEqual(self.mockExperience.name, taco.experiences.first?.name)
            resultCallbackExpectation2.fulfill()

        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testItemsBiggerThanMaxSizeRemovedAndNotSent() throws {
        // verify that the config value for max size is respected, and items beyond this are not retried, and get cleaned out

        // Arrange
        appcues.config.activityStorageMaxSize = 0
        let onPostExpectation1 = expectation(description: "Activity request 1")
        let onPostExpectation2 = expectation(description: "Activity request 2")
        let resultCallbackExpectation1 = expectation(description: "Process result 1")
        let resultCallbackExpectation2 = expectation(description: "Process result 2")
        let activity1 = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
        let activity2 = generateMockActivity(userID: "user2", event: Event(name: "event2", attributes: ["my_key": "my_value2", "another_key": 34]))
        var postCount = 0

        appcues.networking.onPost = { endpoint, body, completion in
            do {
                postCount += 1
                if postCount == 1 {
                    // first attempt we'll simulate failure
                    completion(.failure(URLError(URLError.notConnectedToInternet)))
                    onPostExpectation1.fulfill()
                } else if postCount == 2 {
                    // this should be the synchronous attempt for activity 2 - no retry made
                    let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                    guard case let .qualify(userID) = apiEndpoint else { return XCTFail() }
                    XCTAssertEqual("user2", userID)
                    let data = try NetworkClient.encoder.encode(activity2)
                    XCTAssertEqual(data, body)
                    completion(.success(QualifyResponse(experiences: [self.mockExperience], performedQualification: true, qualificationReason: nil)))
                    onPostExpectation2.fulfill()
                } else {
                    XCTFail()
                }
            } catch {
                XCTFail()
            }
        }

        // Act
        processor.process(activity1) { result in
            guard case .failure = result else { return XCTFail() }
            XCTAssertEqual(1, self.mockStorage.count) // failed item will stay around
            resultCallbackExpectation1.fulfill()
        }
        processor.process(activity2) { result in
            guard case let .success(taco) = result else { return XCTFail() }
            XCTAssertEqual(true, taco.performedQualification)
            XCTAssertEqual(1, taco.experiences.count)
            XCTAssertEqual(self.mockExperience.name, taco.experiences.first?.name)
            XCTAssertEqual(0, self.mockStorage.count) // all cleared out
            resultCallbackExpectation2.fulfill()

        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testClientNetworkIssuesTriggerRetry() throws {
        let resultCallbackExpectation = expectation(description: "Process result")
        let networkIssues = [URLError.notConnectedToInternet, URLError.timedOut, URLError.dataNotAllowed, URLError.internationalRoamingOff]
        var currentError = URLError(networkIssues.first!)
        resultCallbackExpectation.expectedFulfillmentCount = networkIssues.count

        appcues.networking.onPost = { endpoint, body, completion in
            completion(.failure(currentError))
        }

        // Act
        for issue in networkIssues {
            let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
            currentError = URLError(issue)
            processor.process(activity) { result in
                guard case .failure = result else { return XCTFail() }
                resultCallbackExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(networkIssues.count, mockStorage.count)
    }

    func testOtherNetworkIssuesDoNotTriggerRetry() throws {
        let resultCallbackExpectation = expectation(description: "Process result")
        let networkIssues = [URLError.badServerResponse, URLError.unknown, URLError.userAuthenticationRequired, URLError.httpTooManyRedirects]
        var currentError = URLError(networkIssues.first!)
        resultCallbackExpectation.expectedFulfillmentCount = networkIssues.count

        appcues.networking.onPost = { endpoint, body, completion in
            completion(.failure(currentError))
        }

        // Act
        for issue in networkIssues {
            let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
            currentError = URLError(issue)
            processor.process(activity) { result in
                guard case .failure = result else { return XCTFail() }
                resultCallbackExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(0, mockStorage.count)
    }

    func testItemsOlderThanMaxAgeRemovedAndNotSent() throws {
        // verify that the config value for max age is respected, and items beyond this are not retried, and get cleaned out

        // Arrange
        appcues.config.activityStorageMaxAge = 1
        let onPostExpectation1 = expectation(description: "Activity request 1")
        let onPostExpectation2 = expectation(description: "Activity request 2")
        let resultCallbackExpectation1 = expectation(description: "Process result 1")
        let resultCallbackExpectation2 = expectation(description: "Process result 2")
        let activity1 = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))
        let activity2 = generateMockActivity(userID: "user2", event: Event(name: "event2", attributes: ["my_key": "my_value2", "another_key": 34]))
        var postCount = 0

        appcues.networking.onPost = { endpoint, body, completion in
            do {
                postCount += 1
                if postCount == 1 {
                    // first attempt we'll simulate failure
                    completion(.failure(URLError(URLError.notConnectedToInternet)))
                    onPostExpectation1.fulfill()
                } else if postCount == 2 {
                    // this should be the synchronous attempt for activity 2 - no retry made
                    let apiEndpoint = try XCTUnwrap(endpoint as? APIEndpoint)
                    guard case let .qualify(userID) = apiEndpoint else { return XCTFail() }
                    XCTAssertEqual("user2", userID)
                    let data = try NetworkClient.encoder.encode(activity2)
                    XCTAssertEqual(data, body)
                    completion(.success(QualifyResponse(experiences: [self.mockExperience], performedQualification: true, qualificationReason: nil)))
                    onPostExpectation2.fulfill()
                } else {
                    XCTFail()
                }
            } catch {
                XCTFail()
            }
        }

        // Act
        processor.process(activity1) { result in
            guard case .failure = result else { return XCTFail() }
            XCTAssertEqual(1, self.mockStorage.count) // failed item will stay around
            resultCallbackExpectation1.fulfill()
        }
        wait(for: 1.2)
        processor.process(activity2) { result in
            guard case let .success(taco) = result else { return XCTFail() }
            XCTAssertEqual(true, taco.performedQualification)
            XCTAssertEqual(1, taco.experiences.count)
            XCTAssertEqual(self.mockExperience.name, taco.experiences.first?.name)
            XCTAssertEqual(0, self.mockStorage.count) // all cleared out
            resultCallbackExpectation2.fulfill()

        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testActivitySentIfStorageSizeZero() throws {
        // ensure even if config option used to disable all storage/retry - the current item being processed is still sent

        // Arrange
        appcues.config.activityStorageMaxSize = 0
        let onPostExpectation = expectation(description: "Activity request 1")
        let resultCallbackExpectation = expectation(description: "Process result 1")
        let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))

        appcues.networking.onPost = { endpoint, body, completion in
            completion(.success(QualifyResponse(experiences: [self.mockExperience], performedQualification: true, qualificationReason: nil)))
            onPostExpectation.fulfill()
        }

        // Act
        processor.process(activity) { result in
            guard case .success = result else { return XCTFail() }
            resultCallbackExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testThreadSafety() throws {
        // Arrange
        let dispatchGroup = DispatchGroup()
        let completeExpectation = expectation(description: "multi thread")
        completeExpectation.expectedFulfillmentCount = 100
        let activity = generateMockActivity(userID: "user1", event: Event(name: "event1", attributes: ["my_key": "my_value1", "another_key": 33]))

        // Act
        // Process activity on 100 threads
        for _ in 0..<100 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                self.processor.process(activity) { _ in
                    completeExpectation.fulfill()
                }
                dispatchGroup.leave()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    private func generateMockActivity(userID: String, event: Event) -> Activity {
        return Activity(accountID: "00000", userID: userID, events: [event], profileUpdate: nil, groupID: nil, groupUpdate: nil)
    }

    private let mockExperience = Experience(id: UUID(), name: "test_experience", type: "mobile", publishedAt: 1632142800000, traits: [], steps: [], redirectURL: nil, nextContentID: nil)

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
