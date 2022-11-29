//
//  TraitComposerTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-04.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class TraitComposerTests: XCTestCase {

    var appcues: MockAppcues!
    var traitComposer: TraitComposer!
    var traitRegistry: TraitRegistry!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        traitComposer = TraitComposer(container: appcues.container)
        traitRegistry = appcues.container.resolve(TraitRegistry.self)
    }

    func testExperienceLevelTraitsApplied() throws {
        // Arrange
        traitRegistry.register(trait: TestTrait.self)
        traitRegistry.register(trait: TestPresentingTrait.self)

        let stepDecoratingExpectation = expectation(description: "Step decorate called")
        let containerCreatingExpectation = expectation(description: "Create container called")
        let containerDecoratingExpectation = expectation(description: "Container decorate called")
        let wrapperCreatingExpectation = expectation(description: "Create wrapper called")
        let backdropDecoratingExpectation = expectation(description: "Backdrop decorate called")

        let experience = Experience(
            id: UUID(),
            name: "test",
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [
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
            ],
            steps: [
                .child(Experience.Step.Child(traits: []))
            ],
            redirectURL: nil,
            nextContentID: nil)

        // Act
        _ = try traitComposer.package(experience: ExperienceData(experience, trigger: .showCall), stepIndex: Experience.StepIndex(group: 0, item: 0))

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testStepGroupLevelTraitsApplied() throws {
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
        _ = try traitComposer.package(experience: ExperienceData(experience, trigger: .showCall), stepIndex: Experience.StepIndex(group: 0, item: 0))

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
        _ = try traitComposer.package(experience: ExperienceData(experience, trigger: .showCall), stepIndex: Experience.StepIndex(group: 1, item: 0))

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testTraitSpecificity() throws {
        // Verify that for the single instance trait types, a group-level trait replaces an experience level one.

        // Arrange
        traitRegistry.register(trait: TestTrait.self)
        traitRegistry.register(trait: TestPresentingTrait.self)

        let experienceLevelStepDecoratingExpectation = expectation(description: "Step decorate called")
        // ContainerCreating should be superceded by the more specific groupLevelContainerCreatingExpectation
        let experienceLevelContainerCreatingExpectation = expectation(description: "Create container called")
        experienceLevelContainerCreatingExpectation.isInverted = true
        let experienceLevelContainerDecoratingExpectation = expectation(description: "Container decorate called")
        // WrapperCreating should be superceded by the more specific groupLevelWrapperCreatingExpectation
        let experienceLevelWrapperCreatingExpectation = expectation(description: "Create wrapper called")
        experienceLevelWrapperCreatingExpectation.isInverted = true
        let experienceLevelBackdropDecoratingExpectation = expectation(description: "Backdrop decorate called")

        let groupLevelStepDecoratingExpectation = expectation(description: "Step decorate called")
        let groupLevelContainerCreatingExpectation = expectation(description: "Create container called")
        let groupLevelContainerDecoratingExpectation = expectation(description: "Container decorate called")
        let groupLevelWrapperCreatingExpectation = expectation(description: "Create wrapper called")
        let groupLevelBackdropDecoratingExpectation = expectation(description: "Backdrop decorate called")


        let experience = Experience(
            id: UUID(),
            name: "test",
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [
                Experience.Trait(
                    type: "@test/presenting",
                    config: [:]),
                Experience.Trait(
                    type: "@test/trait",
                    config: [
                        "stepDecoratingExpectation": experienceLevelStepDecoratingExpectation as Any,
                        "containerCreatingExpectation": experienceLevelContainerCreatingExpectation as Any,
                        "containerDecoratingExpectation": experienceLevelContainerDecoratingExpectation as Any,
                        "wrapperCreatingExpectation": experienceLevelWrapperCreatingExpectation as Any,
                        "backdropDecoratingExpectation": experienceLevelBackdropDecoratingExpectation as Any
                    ])
            ],
            steps: [
                .group(Experience.Step.Group(
                    id: UUID(uuidString: "d9fbd360-2832-4c8e-a79e-c1731982f1f1")!,
                    type: "group",
                    children: [
                        Experience.Step.Child(traits: [])
                    ],
                    traits: [
                        Experience.Trait(
                            type: "@test/trait",
                            config: [
                                "stepDecoratingExpectation": groupLevelStepDecoratingExpectation as Any,
                                "containerCreatingExpectation": groupLevelContainerCreatingExpectation as Any,
                                "containerDecoratingExpectation": groupLevelContainerDecoratingExpectation as Any,
                                "wrapperCreatingExpectation": groupLevelWrapperCreatingExpectation as Any,
                                "backdropDecoratingExpectation": groupLevelBackdropDecoratingExpectation as Any
                            ])
                    ],
                    actions: [:]
                ))
            ],
            redirectURL: nil,
            nextContentID: nil)

        // Act
        _ = try traitComposer.package(experience: ExperienceData(experience), stepIndex: Experience.StepIndex(group: 0, item: 0))

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
        XCTAssertThrowsError(try traitComposer.package(experience: ExperienceData(experience, trigger: .showCall), stepIndex: Experience.StepIndex(group: 0, item: 0)))
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
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [
                Experience.Trait(
                    type: "@test/presenting",
                    config: [
                        "presentExpectation": presentExpectation,
                        "removeExpectation": removeExpectation
                    ]),
            ],
            steps: [
                .child(Experience.Step.Child(traits: []))
            ],
            redirectURL: nil,
            nextContentID: nil)


        // Act
        let package = try traitComposer.package(experience: ExperienceData(experience, trigger: .showCall), stepIndex: Experience.StepIndex(group: 0, item: 0))

        try package.presenter(nil)
        package.dismisser(nil)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDefaultContainerCreatingTrait() throws {
        let traitInstance = try XCTUnwrap(TraitComposer.DefaultContainerCreatingTrait(config: [:], level: .group))
        let pageMonitor = PageMonitor(numberOfPages: 0, currentPage: 0)
        let container = try traitInstance.createContainer(for: [], with: pageMonitor)
        XCTAssertTrue(container is DefaultContainerViewController)
    }

    func testErrorWhenEmptyStepGroup() throws {
        // Arrange
        let experience = Experience(
            id: UUID(),
            name: "test",
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [],
            steps: [
                .group(Experience.Step.Group(
                    id: UUID(uuidString: "d9fbd360-2832-4c8e-a79e-c1731982f1f1")!,
                    type: "group",
                    children: [],
                    traits: [],
                    actions: [:]
                ))
            ],
            redirectURL: nil,
            nextContentID: nil)
        let experienceData = ExperienceData(experience, trigger: .showCall)

        // Act
        XCTAssertThrowsError(try traitComposer.package(experience: experienceData, stepIndex: Experience.StepIndex(group: 0, item: 0))) { error in
            XCTAssertEqual(
                error as? ExperienceStateMachine.ExperienceError,
                ExperienceStateMachine.ExperienceError.step(experienceData, .initial, "step group D9FBD360-2832-4C8E-A79E-C1731982F1F1 doesn't contain a child step at index 0")
            )
        }
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
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [],
            steps: [
                .group(Experience.Step.Group(
                    id: UUID(),
                    type: "group",
                    children: [
                        Experience.Step.Child(traits: [])
                    ],
                    traits: [
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
                            ]),
                        Experience.Trait(
                            type: "@test/trait",
                            config: [
                                "stepDecoratingExpectation": stepDecoratingExpectation as Any,
                                "containerCreatingExpectation": containerCreatingExpectation as Any,
                                "containerDecoratingExpectation": containerDecoratingExpectation as Any,
                                "wrapperCreatingExpectation": wrapperCreatingExpectation as Any,
                                "backdropDecoratingExpectation": backdropDecoratingExpectation as Any
                            ])
                    ],
                    actions: [:]
                )),
                .child(Experience.Step.Child(traits: [
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
                ]))
            ],
            redirectURL: nil,
            nextContentID: nil)
    }
}

private extension Experience.Step.Child {
    init(traits: [Experience.Trait]) {
        self.init(
            id: UUID(),
            type: "modal",
            content: ExperienceComponent.spacer(ExperienceComponent.SpacerModel(id: UUID(), spacing: nil, style: nil)),
            traits: traits,
            actions: [:]
        )
    }
}

@available(iOS 13.0, *)
extension TraitComposerTests {
    class TestTrait: StepDecoratingTrait, ContainerCreatingTrait, ContainerDecoratingTrait, WrapperCreatingTrait, BackdropDecoratingTrait {
        static let type = "@test/trait"

        let groupID: String?

        var stepDecoratingExpectation: XCTestExpectation?

        var containerCreatingExpectation: XCTestExpectation?

        var containerDecoratingExpectation: XCTestExpectation?

        let wrapperCreatingExpectation: XCTestExpectation?

        var backdropDecoratingExpectation: XCTestExpectation?

        required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
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

        func createContainer(for stepControllers: [UIViewController], with pageMonitor: PageMonitor) throws -> ExperienceContainerViewController {
            containerCreatingExpectation?.fulfill()
            return DefaultContainerViewController(stepControllers: stepControllers, pageMonitor: pageMonitor)
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

    class TestPresentingTrait: PresentingTrait {
        static let type = "@test/presenting"

        let groupID: String?

        var presentExpectation: XCTestExpectation?
        var removeExpectation: XCTestExpectation?

        required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
            self.groupID = config?["groupID"] as? String

            presentExpectation = config?["presentExpectation"] as? XCTestExpectation
            removeExpectation = config?["removeExpectation"] as? XCTestExpectation
        }

        func present(viewController: UIViewController, completion: (() -> Void)?) throws {
            presentExpectation?.fulfill()
            completion?()
        }

        func remove(viewController: UIViewController, completion: (() -> Void)?) {
            removeExpectation?.fulfill()
            completion?()
        }
    }
}
