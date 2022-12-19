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
                    config: TestPresentingTrait.Config()),
                Experience.Trait(
                    type: "@test/trait",
                    config: TestTrait.Config(
                        stepDecoratingExpectation: stepDecoratingExpectation,
                        containerCreatingExpectation: containerCreatingExpectation,
                        containerDecoratingExpectation: containerDecoratingExpectation,
                        wrapperCreatingExpectation: wrapperCreatingExpectation,
                        backdropDecoratingExpectation: backdropDecoratingExpectation))
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

        let stepDecoratingExpectation = expectation(description: "Step decorate called")
        let containerCreatingExpectation = expectation(description: "Create container called")
        let containerDecoratingExpectation = expectation(description: "Container decorate called")
        let wrapperCreatingExpectation = expectation(description: "Create wrapper called")
        let backdropDecoratingExpectation = expectation(description: "Backdrop decorate called")

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
        traitRegistry.register(trait: Test2Trait.self)
        traitRegistry.register(trait: TestPresentingTrait.self)

        // No experience level expectations from @test/trait should be applied because the group also has @test/trait
        let experienceLevelStepDecoratingExpectation = expectation(description: "Experience level step decorate called")
        experienceLevelStepDecoratingExpectation.isInverted = true
        let experienceLevelContainerCreatingExpectation = expectation(description: "Experience level create container called")
        experienceLevelContainerCreatingExpectation.isInverted = true
        let experienceLevelContainerDecoratingExpectation = expectation(description: "Experience level container decorate called")
        experienceLevelContainerDecoratingExpectation.isInverted = true
        let experienceLevelWrapperCreatingExpectation = expectation(description: "Experience level create wrapper called")
        experienceLevelWrapperCreatingExpectation.isInverted = true
        let experienceLevelBackdropDecoratingExpectation = expectation(description: "Experience level backdrop decorate called")
        experienceLevelBackdropDecoratingExpectation.isInverted = true

        // Some experience level expectations from @test/trait-2 should be applied when multiple traits with the same capability are allowed
        let experienceLevel2StepDecoratingExpectation = expectation(description: "Experience level 2 step decorate called")
        // ContainerCreating should be superceded by the more specific groupLevelContainerCreatingExpectation
        let experienceLevel2ContainerCreatingExpectation = expectation(description: "Experience level 2 create container called")
        experienceLevel2ContainerCreatingExpectation.isInverted = true
        let experienceLevel2ContainerDecoratingExpectation = expectation(description: "Experience level 2 container decorate called")
        // WrapperCreating should be superceded by the more specific groupLevelWrapperCreatingExpectation
        let experienceLevel2WrapperCreatingExpectation = expectation(description: "Experience level 2 create wrapper called")
        experienceLevel2WrapperCreatingExpectation.isInverted = true
        let experienceLevel2BackdropDecoratingExpectation = expectation(description: "Experience level 2 backdrop decorate called")


        let groupLevelStepDecoratingExpectation = expectation(description: "Group level step decorate called")
        let groupLevelContainerCreatingExpectation = expectation(description: "Group level create container called")
        let groupLevelContainerDecoratingExpectation = expectation(description: "Group level container decorate called")
        let groupLevelWrapperCreatingExpectation = expectation(description: "Group level create wrapper called")
        let groupLevelBackdropDecoratingExpectation = expectation(description: "Group level backdrop decorate called")


        let experience = Experience(
            id: UUID(),
            name: "test",
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [
                Experience.Trait(
                    type: "@test/presenting",
                    config: TestPresentingTrait.Config()),
                Experience.Trait(
                    type: "@test/trait",
                    config: TestTrait.Config(
                        stepDecoratingExpectation: experienceLevelStepDecoratingExpectation,
                        containerCreatingExpectation: experienceLevelContainerCreatingExpectation,
                        containerDecoratingExpectation: experienceLevelContainerDecoratingExpectation,
                        wrapperCreatingExpectation: experienceLevelWrapperCreatingExpectation,
                        backdropDecoratingExpectation: experienceLevelBackdropDecoratingExpectation
                    )),
                Experience.Trait(
                    type: "@test/trait-2",
                    config: TestTrait.Config(
                        stepDecoratingExpectation: experienceLevel2StepDecoratingExpectation,
                        containerCreatingExpectation: experienceLevel2ContainerCreatingExpectation,
                        containerDecoratingExpectation: experienceLevel2ContainerDecoratingExpectation,
                        wrapperCreatingExpectation: experienceLevel2WrapperCreatingExpectation,
                        backdropDecoratingExpectation: experienceLevel2BackdropDecoratingExpectation
                    ))
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
                            config: TestTrait.Config(
                                stepDecoratingExpectation: groupLevelStepDecoratingExpectation,
                                containerCreatingExpectation: groupLevelContainerCreatingExpectation,
                                containerDecoratingExpectation: groupLevelContainerDecoratingExpectation,
                                wrapperCreatingExpectation: groupLevelWrapperCreatingExpectation,
                                backdropDecoratingExpectation: groupLevelBackdropDecoratingExpectation
                            ))
                    ],
                    actions: [:]
                ))
            ],
            redirectURL: nil,
            nextContentID: nil)

        // Act
        _ = try traitComposer.package(experience: ExperienceData(experience, trigger: .showCall), stepIndex: Experience.StepIndex(group: 0, item: 0))

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
                    config: TestPresentingTrait.Config(
                        presentExpectation: presentExpectation,
                        removeExpectation: removeExpectation
                    ))
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
        let traitInstance = try XCTUnwrap(TraitComposer.DefaultContainerCreatingTrait(configuration: ExperiencePluginConfiguration(nil), level: .group))
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

    func testDecompose() throws {
        // Arrange
        let traits: [ExperienceTrait] = [
            try XCTUnwrap(TestTrait(configuration: ExperiencePluginConfiguration(nil), level: .experience)),
            try XCTUnwrap(TestPresentingTrait(configuration: ExperiencePluginConfiguration(nil), level: .experience))
        ]

        // Act
        let decomposedTraits = TraitComposer.DecomposedTraits(traits: traits)

        // Assert
        XCTAssertEqual(decomposedTraits.allTraitInstances.count, 2)
        XCTAssertEqual(decomposedTraits.stepDecorating.count, 1)
        XCTAssertNotNil(decomposedTraits.containerCreating)
        XCTAssertEqual(decomposedTraits.containerDecorating.count, 1)
        XCTAssertEqual(decomposedTraits.backdropDecorating.count, 1)
        XCTAssertNotNil(decomposedTraits.wrapperCreating)
        XCTAssertNotNil(decomposedTraits.presenting)
    }

    func testAppendDecomposedTraits() throws {
        // Arrange
        let experienceTraits: [ExperienceTrait] = [
            try XCTUnwrap(TestTrait(configuration: ExperiencePluginConfiguration(nil), level: .experience)),
            try XCTUnwrap(TestPresentingTrait(configuration: ExperiencePluginConfiguration(nil), level: .experience))
        ]
        let groupTrait = try XCTUnwrap(TestTrait(configuration: ExperiencePluginConfiguration(nil), level: .experience))
        let decomposedTraits = TraitComposer.DecomposedTraits(traits: experienceTraits)

        // Act
        decomposedTraits.append(contentsOf: TraitComposer.DecomposedTraits(traits: [groupTrait]))

        // Assert
        XCTAssertEqual(decomposedTraits.allTraitInstances.count, 3)
        XCTAssertEqual(decomposedTraits.stepDecorating.count, 2)
        XCTAssertTrue(decomposedTraits.containerCreating === groupTrait, "appended trait takes precedence over existing level")
        XCTAssertEqual(decomposedTraits.containerDecorating.count, 2)
        XCTAssertEqual(decomposedTraits.backdropDecorating.count, 2)
        XCTAssertTrue(decomposedTraits.wrapperCreating === groupTrait, "appended trait takes precedence over existing level")
        XCTAssertNotNil(decomposedTraits.presenting)
    }

    func testPropagateDecomposedTraits() throws {
        // Arrange
        let experienceTraits: [ExperienceTrait] = [
            try XCTUnwrap(Test2Trait(configuration: ExperiencePluginConfiguration(nil), level: .experience)),
            try XCTUnwrap(Test3Trait(configuration: ExperiencePluginConfiguration(nil), level: .group))
        ]
        let decomposedTraits = TraitComposer.DecomposedTraits(traits: experienceTraits)
        let stepTrait = try XCTUnwrap(TestTrait(configuration: ExperiencePluginConfiguration(nil), level: .experience))
        let decomposedStepTraits = TraitComposer.DecomposedTraits(traits: [stepTrait])

        // Act
        decomposedStepTraits.propagateDecorators(from: decomposedTraits)

        // Assert
        XCTAssertEqual(decomposedStepTraits.allTraitInstances.count, 1)
        XCTAssertEqual(decomposedStepTraits.stepDecorating.count, 3)
        XCTAssertEqual(decomposedStepTraits.stepDecorating.map({ type(of: $0).type }), ["@test/trait-2", "@test/trait-3", "@test/trait"])
        XCTAssertNotNil(decomposedStepTraits.containerCreating)
        XCTAssertEqual(decomposedStepTraits.containerDecorating.count, 3)
        XCTAssertEqual(decomposedStepTraits.containerDecorating.map({ type(of: $0).type }), ["@test/trait-2", "@test/trait-3", "@test/trait"])
        XCTAssertEqual(decomposedStepTraits.backdropDecorating.count, 3)
        XCTAssertEqual(decomposedStepTraits.backdropDecorating.map({ type(of: $0).type }), ["@test/trait-2", "@test/trait-3", "@test/trait"])
        XCTAssertNotNil(decomposedStepTraits.containerCreating)
        XCTAssertNil(decomposedStepTraits.presenting)
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
                            config: TestPresentingTrait.Config()),
                        Experience.Trait(
                            type: "@test/trait",
                            config: TestTrait.Config(
                                stepDecoratingExpectation: stepDecoratingExpectation,
                                containerCreatingExpectation: containerCreatingExpectation,
                                containerDecoratingExpectation: containerDecoratingExpectation,
                                wrapperCreatingExpectation: wrapperCreatingExpectation,
                                backdropDecoratingExpectation: backdropDecoratingExpectation
                            )),
                        Experience.Trait(
                            type: "@test/trait",
                            config: TestTrait.Config(
                                stepDecoratingExpectation: stepDecoratingExpectation,
                                containerCreatingExpectation: containerCreatingExpectation,
                                containerDecoratingExpectation: containerDecoratingExpectation,
                                wrapperCreatingExpectation: wrapperCreatingExpectation,
                                backdropDecoratingExpectation: backdropDecoratingExpectation
                            ))
                    ],
                    actions: [:]
                )),
                .child(Experience.Step.Child(traits: [
                    Experience.Trait(
                        type: "@test/presenting",
                        config: TestPresentingTrait.Config()),
                    Experience.Trait(
                        type: "@test/trait",
                        config: TestTrait.Config(
                            stepDecoratingExpectation: stepDecoratingExpectation,
                            containerCreatingExpectation: containerCreatingExpectation,
                            containerDecoratingExpectation: containerDecoratingExpectation,
                            wrapperCreatingExpectation: wrapperCreatingExpectation,
                            backdropDecoratingExpectation: backdropDecoratingExpectation
                        ))
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
            traits: traits,
            actions: [:],
            content: ExperienceComponent.spacer(ExperienceComponent.SpacerModel(id: UUID(), spacing: nil, style: nil))
        )
    }
}

@available(iOS 13.0, *)
extension TraitComposerTests {
    class Test2Trait: TestTrait {
        override class var type: String { "@test/trait-2" }
    }

    class Test3Trait: TestTrait {
        override class var type: String { "@test/trait-3" }
    }

    class TestTrait: StepDecoratingTrait, ContainerCreatingTrait, ContainerDecoratingTrait, WrapperCreatingTrait, BackdropDecoratingTrait {
        struct Config: Decodable {
            let groupID: String?
            let stepDecoratingExpectation: DecodableExpectation?
            let containerCreatingExpectation: DecodableExpectation?
            let containerDecoratingExpectation: DecodableExpectation?
            let wrapperCreatingExpectation: DecodableExpectation?
            let backdropDecoratingExpectation: DecodableExpectation?

            init(groupID: String? = nil,
                 stepDecoratingExpectation: XCTestExpectation? = nil,
                 containerCreatingExpectation: XCTestExpectation? = nil,
                 containerDecoratingExpectation: XCTestExpectation? = nil,
                 wrapperCreatingExpectation: XCTestExpectation? = nil,
                 backdropDecoratingExpectation: XCTestExpectation?) {
                self.groupID = groupID
                self.stepDecoratingExpectation = DecodableExpectation(expectation: stepDecoratingExpectation)
                self.containerCreatingExpectation = DecodableExpectation(expectation: containerCreatingExpectation)
                self.containerDecoratingExpectation = DecodableExpectation(expectation: containerDecoratingExpectation)
                self.wrapperCreatingExpectation = DecodableExpectation(expectation: wrapperCreatingExpectation)
                self.backdropDecoratingExpectation = DecodableExpectation(expectation: backdropDecoratingExpectation)
            }
        }
        class var type: String { "@test/trait" }

        weak var metadataDelegate: AppcuesKit.TraitMetadataDelegate?

        let groupID: String?

        var stepDecoratingExpectation: XCTestExpectation?

        var containerCreatingExpectation: XCTestExpectation?

        var containerDecoratingExpectation: XCTestExpectation?

        let wrapperCreatingExpectation: XCTestExpectation?

        var backdropDecoratingExpectation: XCTestExpectation?

        required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
            let config = configuration.decode(Config.self)
            self.groupID = config?.groupID

            stepDecoratingExpectation = config?.stepDecoratingExpectation?.expectation
            containerCreatingExpectation = config?.containerCreatingExpectation?.expectation
            containerDecoratingExpectation = config?.containerDecoratingExpectation?.expectation
            wrapperCreatingExpectation = config?.wrapperCreatingExpectation?.expectation
            backdropDecoratingExpectation = config?.backdropDecoratingExpectation?.expectation
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

        func undecorate(containerController: AppcuesKit.ExperienceContainerViewController) throws {
            // no-op
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

        func undecorate(backdropView: UIView) throws {
            // no-op
        }
    }

    class TestPresentingTrait: PresentingTrait {
        struct Config: Decodable {
            let groupID: String?
            let presentExpectation: DecodableExpectation?
            let removeExpectation: DecodableExpectation?

            init(groupID: String? = nil, presentExpectation: XCTestExpectation? = nil, removeExpectation: XCTestExpectation? = nil) {
                self.groupID = groupID
                self.presentExpectation = DecodableExpectation(expectation: presentExpectation)
                self.removeExpectation = DecodableExpectation(expectation: removeExpectation)
            }
        }
        static let type = "@test/presenting"

        weak var metadataDelegate: AppcuesKit.TraitMetadataDelegate?

        let groupID: String?

        var presentExpectation: XCTestExpectation?
        var removeExpectation: XCTestExpectation?

        required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
            let config = configuration.decode(Config.self)
            self.groupID = config?.groupID

            presentExpectation = config?.presentExpectation?.expectation
            removeExpectation = config?.removeExpectation?.expectation
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

extension Experience.Trait {
    init(type: String, config: Decodable?) {
        self.init(type: type, configDecoder: FakePluginDecoder(config))
    }
}
