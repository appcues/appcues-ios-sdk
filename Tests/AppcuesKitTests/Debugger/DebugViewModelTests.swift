//
//  DebugViewModelTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-10-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
import Combine
@testable import AppcuesKit

class DebugViewModelTests: XCTestCase {

    var debugViewModel: DebugViewModel!
    var publisher: PassthroughSubject<LoggedEvent, Never>!
    var storage: MockStorage!

    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        publisher = PassthroughSubject<LoggedEvent, Never>()
        storage = MockStorage()
        debugViewModel = DebugViewModel(
            eventPublisher: publisher.eraseToAnyPublisher(),
            storage: storage,
            accountID: "123",
            applicationID: "app-id"
        )
    }

    func testInitialStatus() throws {
        // Arrange

        // Act

        // Assert
        XCTAssertEqual(debugViewModel.accountID, "123")
        XCTAssertEqual(debugViewModel.applicationID, "app-id")
        XCTAssertEqual(debugViewModel.currentUserID, "user-id")
        XCTAssertFalse(debugViewModel.isAnonymous)
        XCTAssertFalse(debugViewModel.trackingPages)
        XCTAssertNil(debugViewModel.filter)
        XCTAssertTrue(debugViewModel.filteredEvents.isEmpty)
        XCTAssertTrue(debugViewModel.experienceStatuses.isEmpty)
    }

    func testRemoveExperience() throws {
        // Arrange
        let id = UUID()
        debugViewModel.experienceStatuses = [
            StatusItem(status: .verified, title: "Showing experience name", id: id)
        ]

        // Act
        debugViewModel.removeExperienceStatus(id: id)

        // Assert
        XCTAssertEqual(debugViewModel.experienceStatuses.count, 0)
    }

    func testProcessScreenView() throws {
        // Arrange
        let update = TrackingUpdate(type: .screen("My Screen"), isInternal: true)

        _ = expectToUpdate(debugViewModel.$trackingPages)

        // Act
        publisher.send(LoggedEvent(from: update))

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertTrue(debugViewModel.trackingPages)
        XCTAssertEqual(debugViewModel.filteredEvents.count, 1)
    }

    func testProcessExperienceStartedEvent() throws {
        // Arrange
        let update = TrackingUpdate(
            type: .event(name: "appcues:v2:experience_started", interactive: false),
            properties: [
                "experienceId": UUID().appcuesFormatted,
                "experienceInstanceId": UUID().appcuesFormatted,
                "experienceName": "Test Experience",
            ],
            isInternal: true
        )

        _ = expectToUpdate(debugViewModel.$experienceStatuses)

        // Act
        publisher.send(LoggedEvent(from: update))

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(debugViewModel.experienceStatuses.count, 1)
        try StatusItem(status: .verified, title: "Showing Test Experience")
            .verifyMatches(debugViewModel.experienceStatuses[safe: 0])
        XCTAssertEqual(debugViewModel.filteredEvents.count, 1)

        debugViewModel.filter = .screen
        XCTAssertEqual(debugViewModel.filteredEvents.count, 0)
    }

    func testProcessExperienceErrorEvent() throws {
        // Arrange
        let update = TrackingUpdate(
            type: .event(name: "appcues:v2:experience_error", interactive: false),
            properties: [
                "experienceId": UUID().appcuesFormatted,
                "experienceInstanceId": UUID().appcuesFormatted,
                "experienceName": "Test Experience",
                "errorId": UUID().appcuesFormatted,
                "message": "Some error message"
            ],
            isInternal: true
        )

        _ = expectToUpdate(debugViewModel.$experienceStatuses)

        // Act
        publisher.send(LoggedEvent(from: update))

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(debugViewModel.experienceStatuses.count, 1)
        try StatusItem(status: .unverified, title: "Content Omitted: Test Experience", subtitle: "Some error message")
            .verifyMatches(debugViewModel.experienceStatuses[safe: 0])
        XCTAssertEqual(debugViewModel.filteredEvents.count, 1)
    }

    func testProcessExperienceStepSeenEvent() throws {
        // Arrange
        let experienceID = UUID().appcuesFormatted
        let initialUpdate = TrackingUpdate(
            type: .event(name: "appcues:v2:experience_started", interactive: false),
            properties: [
                "experienceId": experienceID,
                "experienceInstanceId": UUID().appcuesFormatted,
                "experienceName": "Test Experience",
                "frameID": "my-frame"
            ],
            isInternal: true
        )

        let update = TrackingUpdate(
            type: .event(name: "appcues:v2:step_seen", interactive: false),
            properties: [
                "experienceId": experienceID,
                "experienceInstanceId": UUID().appcuesFormatted,
                "experienceName": "Test Experience",
                "stepId": UUID().appcuesFormatted,
                "stepIndex": Experience.StepIndex.initial.description,
                "frameID": "my-frame"
            ],
            isInternal: true
        )

        _ = expectToUpdate(debugViewModel.$experienceStatuses, count: 2)

        // Act
        publisher.send(LoggedEvent(from: initialUpdate))
        publisher.send(LoggedEvent(from: update))

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(debugViewModel.experienceStatuses.count, 1)
        try StatusItem(status: .verified, title: "Showing Test Experience", subtitle: "Group 1 step 1 (my-frame)")
            .verifyMatches(debugViewModel.experienceStatuses[safe: 0])
    }

    func testProcessExperienceCompletedEvent() throws {
        // Arrange
        let experienceID = UUID().appcuesFormatted
        let initialUpdate = TrackingUpdate(
            type: .event(name: "appcues:v2:step_seen", interactive: false),
            properties: [
                "experienceId": experienceID,
                "experienceInstanceId": UUID().appcuesFormatted,
                "experienceName": "Test Experience",
                "stepId": UUID().appcuesFormatted,
                "stepIndex": Experience.StepIndex.initial.description
            ],
            isInternal: true
        )

        let update = TrackingUpdate(
            type: .event(name: "appcues:v2:experience_completed", interactive: false),
            properties: [
                "experienceId": experienceID,
                "experienceInstanceId": UUID().appcuesFormatted,
                "experienceName": "Test Experience"
            ],
            isInternal: true
        )

        _ = expectToUpdate(debugViewModel.$experienceStatuses, count: 2)

        // Act
        publisher.send(LoggedEvent(from: initialUpdate))
        publisher.send(LoggedEvent(from: update))

        // Assert
        waitForExpectations(timeout: 1)
        XCTAssertEqual(debugViewModel.experienceStatuses.count, 0)
    }

    func testReset() throws {
        // Arrange
        let update = TrackingUpdate(type: .screen("My Screen"), isInternal: true)
        _ = expectToUpdate(debugViewModel.$trackingPages, count: 1)
        publisher.send(LoggedEvent(from: update))
        waitForExpectations(timeout: 1)
        cancellables.removeAll() // remove the subscriber from expectToUpdate above

        debugViewModel.filter = .screen
        XCTAssertEqual(debugViewModel.filteredEvents.count, 1, "Precondition")

        // Act
        debugViewModel.reset()


        // Assert
        XCTAssertNil(debugViewModel.filter)
        XCTAssertEqual(debugViewModel.filteredEvents.count, 0)
        XCTAssertFalse(debugViewModel.trackingPages)
    }

    // MARK: - Helpers

    /// Fulfill an expectation once a new value is set.
    func expectToUpdate<T>(_ publisher: Published<T>.Publisher, count: Int = 1) -> XCTestExpectation {
        var sinkCount = 0
        let expectation = expectation(description: "Test")
        publisher
            .dropFirst()
            .sink { _ in
                sinkCount += 1
                if sinkCount >= count {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        return expectation
    }
}

extension StatusItem {
    func verifyMatches(_ other: StatusItem?, file: StaticString = #file, line: UInt = #line) throws {
        let other = try XCTUnwrap(other)
        XCTAssertEqual(self.status, other.status, file: file, line: line)
        XCTAssertEqual(self.title, other.title, file: file, line: line)
        XCTAssertEqual(self.subtitle, other.subtitle, file: file, line: line)
        XCTAssertEqual(self.detailText, other.detailText, file: file, line: line)
    }
}
