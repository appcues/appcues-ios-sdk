//
//  ExperienceRendererTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

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
        let experience = Experience.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "event tracked")
        // expect some number of analytics events (events/states are tested elsewhere)
        eventExpectation.assertForOverFulfill = false
        appcues.register(subscriber: Mocks.HandlingSubscriber { _ in eventExpectation.fulfill() })

        // Act
        experienceRenderer.show(experience: Experience.mock, published: true) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowUnpublished() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")

        let presentExpectation = expectation(description: "Experience presented")
        let experience = Experience.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "event tracked")
        // no analytics events should be tracked because this is an unpublished flow
        eventExpectation.isInverted = true
        appcues.register(subscriber: Mocks.HandlingSubscriber { _ in eventExpectation.fulfill() })

        // Act
        experienceRenderer.show(experience: Experience.mock, published: false) { result in
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
        let brokenExperience = Experience.mock
        let validExperience = Experience.mock
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
        appcues.register(subscriber: Mocks.HandlingSubscriber { _ in eventExpectation.fulfill() })

        // Act
        experienceRenderer.show(qualifiedExperiences: [brokenExperience, validExperience]) { result in
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
        let experience = Experience.mock
        var preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.show(experience: experience, published: true, completion: nil)
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
        let experience = Experience.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.show(experience: experience, published: true, completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Act
        experienceRenderer.dismissCurrentExperience()  {
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
        let firstExperienceInstance = Experience.mock
        let secondExperienceInstance = Experience.mock
        let preconditionPackage: ExperiencePackage = firstExperienceInstance.packageWithDelay(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Act
        experienceRenderer.show(experience: firstExperienceInstance, published: true) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        experienceRenderer.show(experience: secondExperienceInstance, published: true) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(
                    error as! ExperienceStateMachine.ExperienceError,
                    ExperienceStateMachine.ExperienceError.experience(secondExperienceInstance, "Experience already active")
                )
                failureExpectation.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(firstExperienceInstance.id, secondExperienceInstance.id)
        XCTAssertNotEqual(firstExperienceInstance.instanceID, secondExperienceInstance.instanceID)
        waitForExpectations(timeout: 2)
    }
}

private extension Experience {
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
