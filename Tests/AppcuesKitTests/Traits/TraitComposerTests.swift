//
//  TraitComposerTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-04.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class TraitComposerTests: XCTestCase {

    var appcues: MockAppcues!
    var traitRegistry: TraitRegistry!
    var actionRegistry: ActionRegistry!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        traitRegistry = TraitRegistry(container: appcues.container)
        actionRegistry = ActionRegistry(container: appcues.container)
    }

    func testInitStepGroupingIncluded() throws {
        // Verify that a trait grouping properly includes traits from the group.

        // Arrange
        traitRegistry.register(trait: TestTrait.self)
        traitRegistry.register(trait: TestPresentingTrait.self)

        // `expectedFulfillmentCount = 2` are for traits that have multiple applied
        let stepDecoratingExpectation = expectation(description: "Step decorate called")
        stepDecoratingExpectation.expectedFulfillmentCount = 2
        let containerCreatingExpectation = expectation(description: "Create container called")
        let containerDecoratingExpectation = expectation(description: "Container decorate called")
        containerDecoratingExpectation.expectedFulfillmentCount = 2
        let wrapperCreatingExpectation = expectation(description: "Create wrapper called")
        let backdropDecoratingExpectation = expectation(description: "Backdrop decorate called")
        backdropDecoratingExpectation.expectedFulfillmentCount = 2

        let experience = makeTestExperience(
            stepDecoratingExpectation: stepDecoratingExpectation,
            containerCreatingExpectation: containerCreatingExpectation,
            containerDecoratingExpectation: containerDecoratingExpectation,
            wrapperCreatingExpectation: wrapperCreatingExpectation,
            backdropDecoratingExpectation: backdropDecoratingExpectation)

        // Act
        let traitComposer = try TraitComposer(
            experience: experience,
            stepIndex: 0,
            traitRegistry: traitRegistry)
        _ = try traitComposer.package(actionRegistry: actionRegistry)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testStepLevelTraitsApplied() throws {
        // Verify that a trait grouping properly excludes traits from different groups.
        // Verify that a traits at the step level are properly applied.

        // Arrange
        traitRegistry.register(trait: TestTrait.self)
        traitRegistry.register(trait: TestPresentingTrait.self)

        let experience = makeTestExperience(
            stepDecoratingExpectation: expectation(description: "Step decorate called"),
            containerCreatingExpectation: expectation(description: "Create container called"),
            containerDecoratingExpectation: expectation(description: "Container decorate called"),
            wrapperCreatingExpectation: expectation(description: "Create wrapper called"),
            backdropDecoratingExpectation: expectation(description: "Backdrop decorate called"))

        // Act
        let traitComposer = try TraitComposer(
            experience: experience,
            stepIndex: 1,
            traitRegistry: traitRegistry)
        _ = try traitComposer.package(actionRegistry: actionRegistry)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testMissingPresentingTraitThrows() throws {
        // Verify that an experience without a presenting trait throws an error.

        // Arrange
        // Don't register presenting trait, so TraitComposer doesn't know about any presenting traits
//        traitRegistry.register(trait: TestPresentingTrait.self)

        let experience = makeTestExperience()

        // Act/Assert
        XCTAssertThrowsError(try TraitComposer(
            experience: experience,
            stepIndex: 0,
            traitRegistry: traitRegistry))
    }

    func testPackagePresenter() throws {
        // Verify the present/remove closures are packaged properly.

        // Arrange
        traitRegistry.register(trait: TestPresentingTrait.self)

        let presentExpectation = expectation(description: "Present called")
        let removeExpectation = expectation(description: "Remove called")

        let experience = Experience(
            id: UUID(),
            name: "test",
            traits: [
                Experience.Trait(
                    type: "@test/presenting",
                    config: [
                        "presentExpectation": presentExpectation,
                        "removeExpectation": removeExpectation
                    ]),
            ],
            steps: [
                makeStep(traits: [])
            ])


        // Act
        let traitComposer = try TraitComposer(
            experience: experience,
            stepIndex: 0,
            traitRegistry: traitRegistry)
        let package = try traitComposer.package(actionRegistry: actionRegistry)

        try package.presenter()
        package.dismisser()

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDefaultContainerCreatingTrait() throws {
        let traitInstance = try XCTUnwrap(TraitComposer.DefaultContainerCreatingTrait(config: [:]))
        let container = try traitInstance.createContainer(for: [], targetPageIndex: 0)
        XCTAssertTrue(container is DefaultContainerViewController)
    }

    // MARK: - Helpers

    private func makeTestExperience(
        stepDecoratingExpectation: XCTestExpectation? = nil,
        containerCreatingExpectation: XCTestExpectation? = nil,
        containerDecoratingExpectation: XCTestExpectation? = nil,
        wrapperCreatingExpectation: XCTestExpectation? = nil,
        backdropDecoratingExpectation: XCTestExpectation? = nil
    ) -> Experience {
        Experience(
            id: UUID(),
            name: "test",
            traits: [
                Experience.Trait(
                    type: "@appcues/group",
                    config: [
                        "groupID": "05ac8561-e429-455e-8f49-1dae7c46733f"
                    ]),
                Experience.Trait(
                    type: "@test/presenting",
                    config: [
                        "groupID": "05ac8561-e429-455e-8f49-1dae7c46733f"
                    ]),
                Experience.Trait(
                    type: "@test/trait",
                    config: [
                        "groupID": "05ac8561-e429-455e-8f49-1dae7c46733f",
                        "stepDecoratingExpectation": stepDecoratingExpectation as Any,
                        "containerCreatingExpectation": containerCreatingExpectation as Any,
                        "containerDecoratingExpectation": containerDecoratingExpectation as Any,
                        "wrapperCreatingExpectation": wrapperCreatingExpectation as Any,
                        "backdropDecoratingExpectation": backdropDecoratingExpectation as Any
                    ]),
                Experience.Trait(
                    type: "@test/trait",
                    config: [
                        "groupID": "05ac8561-e429-455e-8f49-1dae7c46733f",
                        "stepDecoratingExpectation": stepDecoratingExpectation as Any,
                        "containerCreatingExpectation": containerCreatingExpectation as Any,
                        "containerDecoratingExpectation": containerDecoratingExpectation as Any,
                        "wrapperCreatingExpectation": wrapperCreatingExpectation as Any,
                        "backdropDecoratingExpectation": backdropDecoratingExpectation as Any
                    ])
            ],
            steps: [
                makeStep(traits: [
                    Experience.Trait(
                        type: "@appcues/group-item",
                        config: ["groupID": "05ac8561-e429-455e-8f49-1dae7c46733f"])
                ]),
                makeStep(traits: [
                    Experience.Trait(
                        type: "@test/presenting",
                        config: [:]),
                    Experience.Trait(
                        type: "@test/trait",
                        config: [
                            "stepDecoratingExpectation": stepDecoratingExpectation as Any,
                            "containerCreatingExpectation": containerCreatingExpectation as Any,
                            "containerDecoratingExpectation": containerDecoratingExpectation as Any,
                            "wrapperCreatingExpectation": wrapperCreatingExpectation as Any,
                            "backdropDecoratingExpectation": backdropDecoratingExpectation as Any
                        ])
                ])
            ])
    }

    private func makeStep(traits: [Experience.Trait]) -> Experience.Step {
        Experience.Step(
            id: UUID(),
            contentType: "application/json",
            content: ExperienceComponent.spacer(ExperienceComponent.SpacerModel(id: UUID(), spacing: nil, style: nil)),
            traits: traits,
            actions: [:])
    }
}

private extension TraitComposerTests {
    struct TestTrait: StepDecoratingTrait, ContainerCreatingTrait, ContainerDecoratingTrait, WrapperCreatingTrait, BackdropDecoratingTrait {
        static let type = "@test/trait"

        let groupID: String?

        var stepDecoratingExpectation: XCTestExpectation?

        var containerCreatingExpectation: XCTestExpectation?

        var containerDecoratingExpectation: XCTestExpectation?

        let wrapperCreatingExpectation: XCTestExpectation?

        var backdropDecoratingExpectation: XCTestExpectation?

        init?(config: [String: Any]?) {
            self.groupID = config?["groupID"] as? String

            stepDecoratingExpectation = config?["stepDecoratingExpectation"] as? XCTestExpectation

            containerCreatingExpectation = config?["containerCreatingExpectation"] as? XCTestExpectation

            containerDecoratingExpectation = config?["containerDecoratingExpectation"] as? XCTestExpectation

            wrapperCreatingExpectation = config?["wrapperCreatingExpectation"] as? XCTestExpectation

            backdropDecoratingExpectation = config?["backdropDecoratingExpectation"] as? XCTestExpectation
        }

        // StepDecoratingTrait

        func decorate(stepController: UIViewController) throws {
            stepDecoratingExpectation?.fulfill()
        }

        // ContainerCreatingTrait

        func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceContainerViewController {
            containerCreatingExpectation?.fulfill()
            return DefaultContainerViewController(stepControllers: stepControllers, targetPageIndex: targetPageIndex)
        }

        // ContainerDecoratingTrait

        func decorate(containerController: ExperienceContainerViewController) throws {
            containerDecoratingExpectation?.fulfill()
        }

        // WrapperCreatingTrait

        func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
            wrapperCreatingExpectation?.fulfill()
            return containerController
        }

        func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
            // nothing
        }

        // BackdropDecoratingTrait

        func decorate(backdropView: UIView) throws {
            backdropDecoratingExpectation?.fulfill()
        }
    }

    struct TestPresentingTrait: PresentingTrait {
        static let type = "@test/presenting"

        let groupID: String?

        var presentExpectation: XCTestExpectation?
        var removeExpectation: XCTestExpectation?

        init?(config: [String: Any]?) {
            self.groupID = config?["groupID"] as? String

            presentExpectation = config?["presentExpectation"] as? XCTestExpectation
            removeExpectation = config?["removeExpectation"] as? XCTestExpectation
        }

        func present(viewController: UIViewController) throws {
            presentExpectation?.fulfill()
        }

        func remove(viewController: UIViewController) {
            removeExpectation?.fulfill()
        }
    }
}
