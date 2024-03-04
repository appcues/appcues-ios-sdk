//
//  AppcuesPresentationDelegateTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2024-03-04.
//  Copyright © 2024 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
final class AppcuesPresentationDelegateTests: XCTestCase {

    var appcues: MockAppcues!

    override func setUpWithError() throws {
        appcues = MockAppcues()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDelegateAppear() throws {
        // Arrange
        let delegate = MockAppcuesPresentationDelegate()
        let experience = ExperienceData.mockEmbed(frameID: "some-frame", trigger: .qualification(reason: .screenView))
        let package = experience.package(onPresent: {}, onDismiss: {})
        let stateMachine = ExperienceStateMachine(
            container: appcues.container,
            initialState: .beginningStep(experience, .initial, package, isFirst: true)
        )
        let view = AppcuesFrameView()
        view.stateMachine = stateMachine
        package.containerController.eventHandler = stateMachine

        let willAppearExpectation = expectation(description: "experienceWillAppear called")
        delegate.experienceWillAppear = { metadata in
            XCTAssertEqual(metadata.id, "54b7ec71-cdaf-4697-affa-f3abd672b3cf")
            XCTAssertEqual(metadata.name, "Mock embedded experience")
            XCTAssertEqual(metadata.renderContext, "some-frame")
            willAppearExpectation.fulfill()
        }

        let didAppearExpectation = expectation(description: "experienceDidAppear called")
        delegate.experienceDidAppear = { metadata in
            XCTAssertEqual(metadata.id, "54b7ec71-cdaf-4697-affa-f3abd672b3cf")
            XCTAssertEqual(metadata.name, "Mock embedded experience")
            XCTAssertEqual(metadata.renderContext, "some-frame")
            didAppearExpectation.fulfill()
        }

        view.presentationDelegate = delegate

        // Act
        try package.presenter({})

        // Assert
        waitForExpectations(timeout: 1.0)
    }

    func testDelegateDisappear() throws {
        // Arrange
        let delegate = MockAppcuesPresentationDelegate()
        let experience = ExperienceData.mockEmbed(frameID: "some-frame", trigger: .qualification(reason: .screenView))
        let package = experience.package(onPresent: {}, onDismiss: {})
        let stateMachine = ExperienceStateMachine(
            container: appcues.container,
            initialState: .endingExperience(experience, .initial, markComplete: true)
        )
        let view = AppcuesFrameView()
        view.stateMachine = stateMachine
        package.containerController.eventHandler = stateMachine

        let willDisappearExpectation = expectation(description: "experienceWillDisappear called")
        delegate.experienceWillDisappear = { metadata in
            XCTAssertEqual(metadata.id, "54b7ec71-cdaf-4697-affa-f3abd672b3cf")
            XCTAssertEqual(metadata.name, "Mock embedded experience")
            XCTAssertEqual(metadata.renderContext, "some-frame")
            willDisappearExpectation.fulfill()
        }

        let didDisappearExpectation = expectation(description: "experienceDidDisappear called")
        delegate.experienceDidDisappear = { metadata in
            XCTAssertEqual(metadata.id, "54b7ec71-cdaf-4697-affa-f3abd672b3cf")
            XCTAssertEqual(metadata.name, "Mock embedded experience")
            XCTAssertEqual(metadata.renderContext, "some-frame")
            didDisappearExpectation.fulfill()
        }

        view.presentationDelegate = delegate

        // Act
        package.dismisser({})

        // Assert
        waitForExpectations(timeout: 1.0)
    }
}

private class MockAppcuesPresentationDelegate: AppcuesPresentationDelegate {
    func canDisplayExperience(metadata: AppcuesPresentationMetadata) -> Bool {
        true
    }

    var experienceWillAppear: ((AppcuesPresentationMetadata) -> Void)?
    func experienceWillAppear(metadata: AppcuesPresentationMetadata) {
        experienceWillAppear?(metadata)
    }

    var experienceDidAppear: ((AppcuesPresentationMetadata) -> Void)?
    func experienceDidAppear(metadata: AppcuesPresentationMetadata) {
        experienceDidAppear?(metadata)
    }

    var experienceWillDisappear: ((AppcuesPresentationMetadata) -> Void)?
    func experienceWillDisappear(metadata: AppcuesPresentationMetadata) {
        experienceWillDisappear?(metadata)
    }

    var experienceDidDisappear: ((AppcuesPresentationMetadata) -> Void)?
    func experienceDidDisappear(metadata: AppcuesPresentationMetadata) {
        experienceDidDisappear?(metadata)
    }
}
