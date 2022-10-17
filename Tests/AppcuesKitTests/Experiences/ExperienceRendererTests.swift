//
//  ExperienceRendererTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class ExperienceRendererTests: XCTestCase {

    var appcues: MockAppcues!
    var experienceRenderer: ExperienceRenderer!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        experienceRenderer = ExperienceRenderer(container: appcues.container)
    }

    func testShowPublished() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")

        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "event tracked")
        // expect some number of analytics events (events/states are tested elsewhere)
        eventExpectation.assertForOverFulfill = false
        appcues.analyticsPublisher.onPublish = { _ in eventExpectation.fulfill() }

        // Act
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowPublishedNormalPriorityReplacesExisting() throws {
        // Arrange
        let preconditionExpectation = expectation(description: "Precondition completion called")
        let completionExpectation = expectation(description: "Completion called")
        // Two experiences should be presented
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.expectedFulfillmentCount = 2
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(
            presentExpectation: presentExpectation,
            dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Set up first experience
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil) { result in
            if case .success = result {
                preconditionExpectation.fulfill()
            }
        }
        XCTAssertEqual(XCTWaiter().wait(for: [preconditionExpectation], timeout: 1), .completed)

        // Act
        experienceRenderer.show(experience: experience.model, priority: .normal, published: true, experiment: nil) { result in
            print(result)
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(XCTWaiter().wait(for: [dismissExpectation, presentExpectation, completionExpectation], timeout: 1), .completed)
    }

    func testShowWhileBeginningInitialExperienceReplacesExisting() throws {
        // Arrange
        let preconditionExpectation = expectation(description: "Precondition completion called")
        let completionExpectation = expectation(description: "Completion called")
        // Two experiences should be presented
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.expectedFulfillmentCount = 2
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(
            presentExpectation: presentExpectation,
            dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Set up first experience
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil) { result in
            if case .success = result {
                preconditionExpectation.fulfill()
            }
        }

        // NOTE: No waiting for initial .show() to complete like the test case above does.

        // Act
        experienceRenderer.show(experience: experience.model, priority: .normal, published: true, experiment: nil) { result in
            print(result)
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowPublishedLowPriorityDoesntReplaceExisting() throws {
        // Arrange
        let preconditionExpectation = expectation(description: "Precondition completion called")
        let presentExpectation = expectation(description: "Experience presented")
        let failureExpectation = expectation(description: "Experience presentation failed called")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Set up first experience
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil) { result in
            if case .success = result {
                preconditionExpectation.fulfill()
            }
        }
        XCTAssertEqual(XCTWaiter().wait(for: [preconditionExpectation, presentExpectation], timeout: 1), .completed)

        // Act
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil) { result in
            print(result)
            if case .failure(ExperienceStateMachine.ExperienceError.experienceAlreadyActive) = result {
                failureExpectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(XCTWaiter().wait(for: [failureExpectation], timeout: 1), .completed)
    }

    func testShowUnpublished() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")

        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "event tracked")
        // no analytics events should be tracked because this is an unpublished flow
        eventExpectation.isInverted = true
        appcues.analyticsPublisher.onPublish = { _ in eventExpectation.fulfill() }

        // Act
        experienceRenderer.show(experience: experience.model, priority: .low, published: false, experiment: nil) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowQualifiedExperiences() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")

        let presentExpectation = expectation(description: "Experience presented")
        let brokenExperience = ExperienceData.mock
        let validExperience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = validExperience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { experience, _ in
            if experience.instanceID == validExperience.instanceID {
                return preconditionPackage
            } else {
                throw TraitError(description: "Presenting capability trait required")
            }
        }

        let eventExpectation = expectation(description: "event tracked")
        // expect some number of analytics events (events/states are tested elsewhere)
        eventExpectation.assertForOverFulfill = false
        appcues.analyticsPublisher.onPublish = { _ in eventExpectation.fulfill() }

        // Act
        experienceRenderer.show(qualifiedExperiences: [brokenExperience.model, validExperience.model], priority: .low, experiments: [:]) { result in
            print(result)
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowStepReference() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")

        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.mock
        var preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil, completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Now that we've shown the first step, set the expectation for the 2nd step transition that we're testing
        let presentExpectation = expectation(description: "Experience presented")
        preconditionPackage = experience.package(presentExpectation: presentExpectation)

        // Step ID in a different container
        let targetID = try XCTUnwrap(UUID(uuidString: "03652bd5-f0cb-44f0-9274-e95b4441d857"))

        // Act
        experienceRenderer.show(stepInCurrentExperience: .stepID(targetID)) {
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDismissExperience() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")

        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil, completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Act
        experienceRenderer.dismissCurrentExperience(markComplete: false) { _ in
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowSameExperienceFromTwoSources() throws {
        // Test that the state machine observers can properly distingush between the same experience ID.

        // Arrange
        let completionExpectation = expectation(description: "First experience: success called")
        let failureExpectation = expectation(description: "Second experience: failure called")

        let presentExpectation = expectation(description: "Experience presented")
        let firstExperienceInstance = ExperienceData.mock
        let secondExperienceInstance = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = firstExperienceInstance.packageWithDelay(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Act
        experienceRenderer.show(experience: firstExperienceInstance.model, priority: .low, published: true, experiment: nil) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        experienceRenderer.show(experience: secondExperienceInstance.model, priority: .low, published: true, experiment: nil) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(
                    error as! ExperienceStateMachine.ExperienceError,
                    ExperienceStateMachine.ExperienceError.experienceAlreadyActive(ignoredExperience: secondExperienceInstance)
                )
                failureExpectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(firstExperienceInstance.id, secondExperienceInstance.id)
        XCTAssertNotEqual(firstExperienceInstance.instanceID, secondExperienceInstance.instanceID)
        waitForExpectations(timeout: 2)
    }

    func testShowStepDismissCallsCompletion() throws {
        // sc-38212: Test that the completion handler is called when continuing from
        // last step in an experience (which dismisses the experience).

        // Arrange
        let completionExpectation = expectation(description: "Completion called")
        let dismissExpectation = expectation(description: "Experience dismissed")

        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.singleStepMock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.show(experience: experience.model, priority: .low, published: true, experiment: nil, completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Act
        experienceRenderer.show(stepInCurrentExperience: .offset(1)) {
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }
}

private extension ExperienceData {
    @available(iOS 13.0, *)
    func packageWithDelay(presentExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil) -> ExperiencePackage {
        let containerController = Mocks.ContainerViewController(stepControllers: [UIViewController()])
        return ExperiencePackage(
            traitInstances: [],
            steps: self.steps[0].items,
            containerController: containerController,
            wrapperController: containerController,
            presenter: { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presentExpectation?.fulfill()
                    completion?()
                }
            },
            dismisser: { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismissExpectation?.fulfill()
                    completion?()
                }
            })
    }
}
