//
//  EmbedExperienceRendererTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-07-05.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class EmbedExperienceRendererTests: XCTestCase {

    let screenTrigger = ExperienceTrigger.qualification(reason: .screenView)

    var appcues: MockAppcues!
    var experienceRenderer: ExperienceRenderer!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        experienceRenderer = ExperienceRenderer(container: appcues.container)
    }

    /// Tests the basic scenario where a frame is registered and a screen view qualification returns an embedded experience for the frame.
    @MainActor
    func testQualifyIntoExistingFrame() async throws {
        // Arrange
        let experience = ExperienceData.mockEmbed(frameID: "frame1", trigger: screenTrigger)

        let presentExpectation = expectation(description: "Experience presented")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "experience started")
        appcues.analyticsPublisher.onPublish = { update in
            if case .event(name: "appcues:v2:experience_started", interactive: false) = update.type {
                eventExpectation.fulfill()
            }
        }

        let frame = AppcuesFrameView()
        // Simulate the relevant part of Appcues.register(frameID:)
        try await experienceRenderer.start(owner: frame, forContext: .embed(frameID: "frame1"))

        // Act
        try await experienceRenderer.processAndShow(qualifiedExperiences: [experience], reason: screenTrigger)

        // Assert
        await fulfillment(of: [presentExpectation, eventExpectation], timeout: 1)
    }

    /// Tests the basic scenario where a screen view qualification returns an embedded experience for the frame AND THEN a frame is subsequently registered.
    /// For example, a below-the-fold frame.
    @MainActor
    func testLoadFromCacheIntoNewFrame() async throws {
        // Arrange
        let experience = ExperienceData.mockEmbed(frameID: "frame1", trigger: screenTrigger)

        let presentExpectation = expectation(description: "Experience presented")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        let errorExpectation = expectation(description: "experience error event")
        let recoveredExpectation = expectation(description: "experience recovered event")
        let eventExpectation = expectation(description: "experience started")
        appcues.analyticsPublisher.onPublish = { update in
            switch update.type {
            case .event(name: "appcues:v2:experience_error", interactive: false):
                errorExpectation.fulfill()
            case .event(name: "appcues:v2:experience_recovered", interactive: false):
                recoveredExpectation.fulfill()
            case .event(name: "appcues:v2:experience_started", interactive: false):
                eventExpectation.fulfill()
            default:
                break
            }
        }

        do {
            try await experienceRenderer.processAndShow(qualifiedExperiences: [experience], reason: screenTrigger)

            // Side test: non-screenView qualifications shouldn't affect the cache (and each will fail with renderDeferred).
            // See testScreenViewClearsCache() below for the screenView test.
            try await experienceRenderer.processAndShow(qualifiedExperiences: [], reason: .qualification(reason: .eventTrigger))
            try await experienceRenderer.processAndShow(qualifiedExperiences: [], reason: .showCall)
            try await experienceRenderer.processAndShow(qualifiedExperiences: [], reason: .preview)
            try await experienceRenderer.processAndShow(qualifiedExperiences: [], reason: .deepLink)
            try await experienceRenderer.processAndShow(qualifiedExperiences: [], reason: .launchExperienceAction(fromExperienceID: UUID()))
            try await experienceRenderer.processAndShow(qualifiedExperiences: [], reason: .experienceCompletionAction(fromExperienceID: UUID()))
        } catch {
            guard case ExperienceRendererError.renderDeferred(.embed(frameID: "frame1"), _) = error else {
                XCTFail("unexpected error")
                throw error
            }
        }

        // Act
        let frame = AppcuesFrameView()
        // Simulate the relevant part of Appcues.register(frameID:)
        try await experienceRenderer.start(owner: frame, forContext: .embed(frameID: "frame1"))

        // Assert
        await fulfillment(of: [errorExpectation, recoveredExpectation, presentExpectation, eventExpectation], timeout: 1, enforceOrder: true)
    }

    /// Tests the case where a new screen view clears the cache of embedded experiences, so nothing loads into the frame.
    @MainActor
    func testScreenViewClearsCache() async throws {
        // Arrange
        let experience = ExperienceData.mockEmbed(frameID: "frame1", trigger: screenTrigger)

        let presentExpectation = expectation(description: "Experience presented")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "experience started")
        appcues.analyticsPublisher.onPublish = { update in
            if case .event(name: "appcues:v2:experience_started", interactive: false) = update.type {
                eventExpectation.fulfill()
            }
        }

        do {
            try await experienceRenderer.processAndShow(qualifiedExperiences: [experience], reason: screenTrigger)
        } catch {
            guard case ExperienceRendererError.renderDeferred(.embed(frameID: "frame1"), _) = error else {
                XCTFail("unexpected error")
                throw error
            }
        }

        // Act
        try await experienceRenderer.processAndShow(qualifiedExperiences: [], reason: .qualification(reason: .screenView))
        // Expect nothing since the cache should be cleared
        presentExpectation.isInverted = true
        eventExpectation.isInverted = true

        let frame = AppcuesFrameView()
        // Simulate the relevant part of Appcues.register(frameID:)
        try await experienceRenderer.start(owner: frame, forContext: .embed(frameID: "frame1"))

        // Assert
        await fulfillment(of: [presentExpectation, eventExpectation], timeout: 1, enforceOrder: true)
    }

    /// Tests the case where a frame shows an embed and then the same frameID is subsequently registered again and so loads the experience again.
    /// For example, a frame inside a UITableViewCell.
    @MainActor
    func testShownEmbedNotRemovedFromCache() async throws {
        // Arrange
        let experience = ExperienceData.mockEmbed(frameID: "frame1", trigger: screenTrigger)

        let presentExpectation = expectation(description: "Experience presented")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "experience started")
        appcues.analyticsPublisher.onPublish = { update in
            if case .event(name: "appcues:v2:experience_started", interactive: false) = update.type {
                eventExpectation.fulfill()
            }
        }

        presentExpectation.expectedFulfillmentCount = 2
        eventExpectation.expectedFulfillmentCount = 2

        let frame = AppcuesFrameView()
        // Simulate the relevant part of Appcues.register(frameID:)
        try await experienceRenderer.start(owner: frame, forContext: .embed(frameID: "frame1"))

        // Act
        try await experienceRenderer.processAndShow(qualifiedExperiences: [experience], reason: screenTrigger)

        // Same frame loads the content again
        // Simulate the relevant part of Appcues.register(frameID:)
        try await experienceRenderer.start(owner: frame, forContext: .embed(frameID: "frame1"))

        // Dismiss the experience, removing it from the cache
        try await experienceRenderer.dismiss(inContext: .embed(frameID: "frame1"), markComplete: false)

        // Same frame registers again, but this time has no content available because it was completed above.
        // Simulate the relevant part of Appcues.register(frameID:)
        try await experienceRenderer.start(owner: frame, forContext: .embed(frameID: "frame1"))

        // Assert
        await fulfillment(of: [presentExpectation, eventExpectation], timeout: 1, enforceOrder: true)
    }
    

    /// Tests the case where a frame is registered and the de-inited before an embed qualifies.
    @MainActor
    func testFrameMemoryRetain() async throws {
        // Arrange
        let experience = ExperienceData.mockEmbed(frameID: "frame1", trigger: screenTrigger)

        let presentExpectation = expectation(description: "Experience presented")
        let preconditionPackage: ExperiencePackage = experience.package(presentExpectation: presentExpectation)
        appcues.traitComposer.setPackage { _, _ in preconditionPackage }

        let eventExpectation = expectation(description: "experience started")
        appcues.analyticsPublisher.onPublish = { update in
            if case .event(name: "appcues:v2:experience_started", interactive: false) = update.type {
                eventExpectation.fulfill()
            }
        }

        var frame: AppcuesFrameView? = AppcuesFrameView()
        // Simulate the relevant part of Appcues.register(frameID:)
        try await experienceRenderer.start(owner: frame!, forContext: .embed(frameID: "frame1"))

        // Act
        
        frame = nil

        // Expect nothing since the render context for frame1 should be gone now
        presentExpectation.isInverted = true
        eventExpectation.isInverted = true

        do {
            try await experienceRenderer.processAndShow(qualifiedExperiences: [experience], reason: screenTrigger)
        } catch {
            guard case ExperienceRendererError.renderDeferred(.embed(frameID: "frame1"), _) = error else {
                XCTFail("unexpected error")
                throw error
            }
        }

        // Assert
        await fulfillment(of: [presentExpectation, eventExpectation], timeout: 1, enforceOrder: true)
    }

}

extension Experience {
    static func mockEmbed(frameID: String) -> Experience {
        Experience(
            id: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
            name: "Mock embedded experience",
            type: "mobile",
            publishedAt: 1632142800000,
            context: nil,
            traits: [],
            steps: [
                Experience.Step(
                    fixedID: "fb529214-3c78-4d6d-ba93-b55d22497ca1",
                    children: [
                        Step.Child(fixedID: "e03ae132-91b7-4cb0-9474-7d4a0e308a07")
                    ]
                )
            ],
            redirectURL: nil,
            nextContentID: nil,
            renderContext: .embed(frameID: frameID)
        )
    }
}

extension ExperienceData {
    static func mockEmbed(frameID: String, trigger: ExperienceTrigger) -> ExperienceData {
        ExperienceData(
            .mockEmbed(frameID: frameID),
            trigger: trigger,
            priority: .low,
            published: true,
            experiment: nil,
            requestID: nil,
            error: nil
        )
    }
}
