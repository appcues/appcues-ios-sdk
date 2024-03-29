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
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true)) { result in
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
        // Experiences with different instanceIDs
        let experience1 = ExperienceData.mock
        let experience2 = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience1.package(
            presentExpectation: presentExpectation,
            dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Set up first experience
        experienceRenderer.processAndShow(experience: ExperienceData(experience1.model, trigger: .showCall, priority: .low, published: true)) { result in
            if case .success = result {
                preconditionExpectation.fulfill()
            }
        }
        wait(for: [preconditionExpectation], timeout: 1)

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience2.model, trigger: .showCall, priority: .normal, published: true)) { result in
            print(result)
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        wait(for: [dismissExpectation, presentExpectation, completionExpectation], timeout: 1)
    }

    func testShowWhileBeginningInitialExperienceReplacesExisting() throws {
        // Arrange
        let preconditionExpectation = expectation(description: "Precondition completion called")
        let completionExpectation = expectation(description: "Completion called")
        // Two experiences should be presented
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.expectedFulfillmentCount = 2
        let dismissExpectation = expectation(description: "Experience dismissed")
        // Experiences with different instanceIDs
        let experience1 = ExperienceData.mock
        let experience2 = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience1.package(
            presentExpectation: presentExpectation,
            dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Set up first experience
        experienceRenderer.processAndShow(experience: ExperienceData(experience1.model, trigger: .showCall, priority: .low, published: true)) { result in
            if case .success = result {
                preconditionExpectation.fulfill()
            }
        }

        // NOTE: No waiting for initial .show() to complete like the test case above does.

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience2.model, trigger: .showCall, priority: .normal, published: true)) { result in
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
        // Experiences with different instanceIDs
        let experience1 = ExperienceData.mock
        let experience2 = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience1.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Set up first experience
        experienceRenderer.processAndShow(experience: ExperienceData(experience1.model, trigger: .showCall, priority: .low, published: true)) { result in
            if case .success = result {
                preconditionExpectation.fulfill()
            }
        }
        wait(for: [preconditionExpectation, presentExpectation], timeout: 1)

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience2.model, trigger: .showCall, priority: .low, published: true)) { result in
            print(result)
            if case .failure(ExperienceStateMachine.ExperienceError.experienceAlreadyActive) = result {
                failureExpectation.fulfill()
            }
        }

        // Assert
        wait(for: [failureExpectation], timeout: 1)
    }

    func testShowPublishedSameInstanceDoesntReplaceExisting() throws {
        // Arrange
        let preconditionExpectation = expectation(description: "Precondition completion called")
        let completionExpectation = expectation(description: "Completion called")
        let presentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        // No experience should be dismissed because we're showing the same instance
        dismissExpectation.isInverted = true
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(
            presentExpectation: presentExpectation,
            dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Set up first experience
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true)) { result in
            if case .success = result {
                preconditionExpectation.fulfill()
            }
        }
        wait(for: [preconditionExpectation], timeout: 1)

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .normal, published: true)) { result in
            print(result)
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        wait(for: [dismissExpectation, presentExpectation, completionExpectation], timeout: 1)
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
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: false)) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowQualifiedExperiences() throws {
        // Arrange
        let presentExpectation = expectation(description: "Experience presented")

        let brokenExperience = ExperienceData.mock
        let validExperience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = validExperience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { experience, _ in
            if experience.instanceID == validExperience.instanceID {
                return preconditionPackage
            } else {
                throw AppcuesTraitError(description: "Presenting capability trait required")
            }
        }

        let eventExpectation = expectation(description: "event tracked")
        // expect some number of analytics events (events/states are tested elsewhere)
        eventExpectation.assertForOverFulfill = false
        appcues.analyticsPublisher.onPublish = { _ in eventExpectation.fulfill() }

        // Act
        experienceRenderer.processAndShow(qualifiedExperiences: [
            ExperienceData(brokenExperience.model, trigger: .qualification(reason: .screenView), priority: .low),
            ExperienceData(validExperience.model, trigger: .qualification(reason: .screenView), priority: .low)
        ], reason: .qualification(reason: .screenView))

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
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true), completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Now that we've shown the first step, set the expectation for the 2nd step transition that we're testing
        let presentExpectation = expectation(description: "Experience presented")
        preconditionPackage = experience.package(presentExpectation: presentExpectation)

        // Step ID in a different container
        let targetID = try XCTUnwrap(UUID(uuidString: "03652bd5-f0cb-44f0-9274-e95b4441d857"))

        // Act
        experienceRenderer.show(step: .stepID(targetID), inContext: .modal) {
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
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true), completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Act
        experienceRenderer.dismiss(inContext: .modal, markComplete: false) { _ in
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDismissExperienceLastStep() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")

        var updates: [TrackingUpdate] = []
        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.singleStepMock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true), completion: nil)
        appcues.analyticsPublisher.onPublish = { update in updates.append(update) }
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Act
        experienceRenderer.dismiss(inContext: .modal, markComplete: false) { _ in
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
        let lastUpdate = try XCTUnwrap(updates.last)
        // confirm that dismiss on last step triggers experience_dismissed analytics, not experience_completed
        XCTAssertEqual(lastUpdate.type, .event(name: "appcues:v2:experience_dismissed", interactive: false))
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
        experienceRenderer.processAndShow(experience: ExperienceData(firstExperienceInstance.model, trigger: .showCall, priority: .low, published: true)) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        experienceRenderer.processAndShow(experience: ExperienceData(secondExperienceInstance.model, trigger: .showCall, priority: .low, published: true)) { result in
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
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true), completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        // Act
        experienceRenderer.show(step: .offset(1), inContext: .modal) {
            completionExpectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowControlExperimentFail() throws {
        // Arrange
        let failureExpectation = expectation(description: "Failure completion called")
        let presentExpectation = expectation(description: "Experience presented")
        presentExpectation.isInverted = true
        let experience = ExperienceData.singleStepMock
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "control", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment)) { result in
            if case .failure = result {
                failureExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowExposedExperiment() throws {
        // Arrange
        let completionExpectation = expectation(description: "Completion called")
        let presentExpectation = expectation(description: "Experience presented")
        let experience = ExperienceData.singleStepMock
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "exposed", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment)) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testExperimentEnteredControlAnalytics() throws {
        // Arrange
        let analyticsExpectation = expectation(description: "Triggered experiment_entered analytics")
        let experience = ExperienceData.singleStepMock
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "control", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let properties: [String: Any] = [
            "experimentId": experimentID.appcuesFormatted,
            "experimentGroup": "control",
            "experimentExperienceId": experience.id.appcuesFormatted,
            "experimentGoalId": "my-goal",
            "experimentContentType": "my-content-type"
        ]
        var experimentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            if case let .event(name, interactive) = update.type,
                name == "appcues:experiment_entered",
                !interactive {
                experimentUpdate = update
                analyticsExpectation.fulfill()
            }
        }

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment), completion: nil)

        // Assert
        waitForExpectations(timeout: 1)
        properties.verifyPropertiesMatch(experimentUpdate?.properties)
    }

    func testExperimentEnteredExposedAnalytics() throws {
        // Arrange
        let analyticsExpectation = expectation(description: "Triggered experiment_entered analytics")
        let experience = ExperienceData.singleStepMock
        let experimentID = UUID(uuidString: "6ce90d1d-4de2-41a6-bc93-07ae23b728c5")!
        let experiment = Experiment(group: "exposed", experimentID: experimentID, experienceID: experience.id, goalID: "my-goal", contentType: "my-content-type")
        let properties: [String: Any] = [
            "experimentId": experimentID.appcuesFormatted,
            "experimentGroup": "exposed",
            "experimentExperienceId": experience.id.appcuesFormatted,
            "experimentGoalId": "my-goal",
            "experimentContentType": "my-content-type"
        ]
        var experimentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in
            if case let .event(name, interactive) = update.type,
                name == "appcues:experiment_entered",
                !interactive {
                experimentUpdate = update
                analyticsExpectation.fulfill()
            }
        }

        // Act
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true, experiment: experiment), completion: nil)

        // Assert
        waitForExpectations(timeout: 1)
        properties.verifyPropertiesMatch(experimentUpdate?.properties)
    }

    func testReset() throws {
        let preconditionPresentExpectation = expectation(description: "Experience presented")
        let dismissExpectation = expectation(description: "Experience dismissed")
        let experience = ExperienceData.mock
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: preconditionPresentExpectation, dismissExpectation: dismissExpectation)
        appcues.traitComposer.onPackage = { _, _ in preconditionPackage }
        experienceRenderer.processAndShow(experience: ExperienceData(experience.model, trigger: .showCall, priority: .low, published: true), completion: nil)
        wait(for: [preconditionPresentExpectation], timeout: 1)

        appcues.analyticsPublisher.onPublish = { update in
            XCTFail("no analytics expected")
        }

        // Act
        experienceRenderer.resetAll()

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDirectoryThreadSafety() throws {
        // Arrange
        let dispatchGroup = DispatchGroup()
        let completeExpectation = expectation(description: "multi thread")
        completeExpectation.expectedFulfillmentCount = 100

        let directory = StateMachineDirectory()

        // Safely init UIKit objects on main thread
        let views = Array(repeating: AppcuesFrameView(), count: 100)

        // Act
        // Use the directory on 100 threads
        for i in 0..<100 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                directory[ownerFor: .embed(frameID: "frame\(i)")] = views[i]
                completeExpectation.fulfill()
                dispatchGroup.leave()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }
}

@available(iOS 13.0, *)
private extension ExperienceData {
    @available(iOS 13.0, *)
    func packageWithDelay(presentExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil) -> ExperiencePackage {
        let pageMonitor = AppcuesExperiencePageMonitor(numberOfPages: 1, currentPage: 0)
        let containerController = Mocks.ContainerViewController(stepControllers: [UIViewController()], pageMonitor: pageMonitor)
        return ExperiencePackage(
            traitInstances: [],
            stepDecoratingTraitUpdater: { new, prev in },
            steps: self.steps[0].items,
            containerController: containerController,
            wrapperController: containerController,
            pageMonitor: pageMonitor,
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
