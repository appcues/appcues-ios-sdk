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
        let presentExpectation = expectation(description: "Experience presented")
        let experience = Experience.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "event tracked")
        // Expecting: appcues:flow_attempted, appcues:step_attempted
        eventExpectation.expectedFulfillmentCount = 2
        appcues.register(subscriber: MockSubscriber { _ in eventExpectation.fulfill() })

        // Act
        experienceRenderer.show(experience: Experience.mock, published: true)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowUnpublished() throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")
        let experience = Experience.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "event tracked")
        // no analytics events should be tracked because this is an unpublished flow
        eventExpectation.isInverted = true
        appcues.register(subscriber: MockSubscriber { _ in eventExpectation.fulfill() })

        // Act
        experienceRenderer.show(experience: Experience.mock, published: false)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowStepReference() throws {
        // Arrange
        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let experience = Experience.mock
        var preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.show(experience: experience, published: true)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Now that we've shown the first step, set the expectation for the 2nd step transition that we're testing
        let presentExpectation = expectation(description: "Experience presented")
        preconditionPackage = experience.package(presentExpectation: presentExpectation)

        // Act
        experienceRenderer.show(stepInCurrentExperience: .index(1))

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDismissExperience() throws {
        // Arrange
        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = Experience.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.show(experience: experience, published: true)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Act
        experienceRenderer.dismissCurrentExperience()

        // Assert
        waitForExpectations(timeout: 1)
    }
}

private class MockSubscriber: AnalyticsSubscribing {
    var handler: (TrackingUpdate) -> Void

    init(handler: @escaping (TrackingUpdate) -> Void) {
        self.handler = handler
    }

    func track(update: TrackingUpdate) {
        handler(update)
    }
}

private extension Experience {
    static var mock: Experience {
        Experience(
            id: UUID(),
            name: "test",
            traits: [],
            steps: [
                Experience.Step(fixedID: "fb529214-3c78-4d6d-ba93-b55d22497ca1"),
                Experience.Step(fixedID: "e03ae132-91b7-4cb0-9474-7d4a0e308a07")
            ])
    }

    func package(presentExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil) -> ExperiencePackage {
        let containerController = DefaultContainerViewController(stepControllers: [UIViewController()])
        return ExperiencePackage(
            steps: [self.steps[0]],
            containerController: containerController,
            wrapperController: containerController,
            presenter: { presentExpectation?.fulfill() },
            dismisser: { dismissExpectation?.fulfill(); $0?() })
    }
}
