//
//  ExperienceStateMachine+AnalyticsObserverTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-21.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ExperienceStateMachine_AnalyticsObserverTests: XCTestCase {

    var appcues: MockAppcues!
    private var analyticsSubscriber: Mocks.TestSubscriber!
    var observer: ExperienceStateMachine.AnalyticsObserver!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        analyticsSubscriber = Mocks.TestSubscriber()
        appcues.register(subscriber: analyticsSubscriber)
        observer = ExperienceStateMachine.AnalyticsObserver(container: appcues.container)
    }

    func testEvaluateIdlingState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.idling))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }

    func testEvaluateBeginningExperienceState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.beginningExperience(Experience.mock)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }

    func testEvaluateBeginningStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.beginningStep(Experience.mock, .initial, Experience.mock.package(), isFirst: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }

    func testEvaluateRenderingFirstStepState() throws {
        // Precondition
        XCTAssertNil(appcues.storage.lastContentShownAt)

        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(Experience.mock, .initial, Experience.mock.package(), isFirst: true)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 2)
        XCTAssertEqual(analyticsSubscriber.lastUpdate?.type, .event(name: "appcues:v2:step_seen", interactive: false))
        XCTAssertNotNil(appcues.storage.lastContentShownAt)
    }

    func testEvaluateRenderingStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.renderingStep(Experience.mock, .initial, Experience.mock.package(), isFirst: false)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        XCTAssertEqual(analyticsSubscriber.lastUpdate?.type, .event(name: "appcues:v2:step_seen", interactive: false))
    }

    func testEvaluateEndingStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingStep(Experience.mock, .initial, Experience.mock.package())))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        XCTAssertEqual(analyticsSubscriber.lastUpdate?.type, .event(name: "appcues:v2:step_completed", interactive: false))
    }

    func testEvaluateEndingExperienceState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(Experience.mock, .initial)))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        XCTAssertEqual(analyticsSubscriber.lastUpdate?.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
    }

    func testEvaluateEndingExperienceLastStepState() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .success(.endingExperience(Experience.mock, Experience.StepIndex(group: 1, item: 0))))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        XCTAssertEqual(analyticsSubscriber.lastUpdate?.type, .event(name: "appcues:v2:experience_completed", interactive: false))
    }

    func testEvaluateExperienceError() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.experience(Experience.mock, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        XCTAssertEqual(analyticsSubscriber.lastUpdate?.type, .event(name: "appcues:v2:experience_error", interactive: false))
    }

    func testEvaluateStepError() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.step(Experience.mock, .initial, "error")))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 1)
        XCTAssertEqual(analyticsSubscriber.lastUpdate?.type, .event(name: "appcues:v2:step_error", interactive: false))
    }

    func testEvaluateNoTransitionError() throws {
        // Act
        let isCompleted = observer.evaluateIfSatisfied(result: .failure(.noTransition))

        // Assert
        XCTAssertFalse(isCompleted)
        XCTAssertEqual(analyticsSubscriber.trackedUpdates, 0)
    }
}
