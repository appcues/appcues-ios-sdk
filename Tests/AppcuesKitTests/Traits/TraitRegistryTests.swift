//
//  TraitRegistryTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-01.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class TraitRegistryTests: XCTestCase {

    var appcues: MockAppcues!
    var traitRegistry: TraitRegistry!
    var logger: DebugLogger!

    override func setUpWithError() throws {
        logger = DebugLogger(previousLogger: nil)
        appcues = MockAppcues()
        appcues.config.logger = logger
        traitRegistry = TraitRegistry(container: appcues.container)
    }

    func testRegister() throws {
        // Arrange
        let traitModel = Experience.Trait(type: TestTrait.type, config: nil)

        // Act
        traitRegistry.register(trait: TestTrait.self)

        // Assert
        let traitInstances = traitRegistry.instances(for: [traitModel], level: .group, renderContext: .modal)
        XCTAssertEqual(traitInstances.count, 1)
    }

    func testUnknownTrait() throws {
        // Arrange
        let traitModel = Experience.Trait(type: "@unknown/trait", config: nil)

        // Act
        traitRegistry.register(trait: TestTrait.self)

        // Assert
        let traitInstances = traitRegistry.instances(for: [traitModel], level: .group, renderContext: .modal)
        XCTAssertEqual(traitInstances.count, 0)
    }

    func testDuplicateTypeRegistrations() throws {
        // Arrange
        let traitModel = Experience.Trait(type: TestTrait.type, config: nil)

        // Act
        let successfullyRegisteredTrait1 = traitRegistry.register(trait: TestTrait.self)
        let successfullyRegisteredTrait2 = traitRegistry.register(trait: TestTrait.self)

        // Assert
        XCTAssertTrue(successfullyRegisteredTrait1)
        XCTAssertFalse(successfullyRegisteredTrait2)
        let traitInstances = traitRegistry.instances(for: [traitModel], level: .group, renderContext: .modal)
        XCTAssertEqual(traitInstances.count, 1)

        XCTAssertEqual(logger.log.count, 1)
        let log = try XCTUnwrap(logger.log.first)
        XCTAssertEqual(log.level, .error)
        XCTAssertEqual(log.message, "Trait of type @test/trait is already registered.")
    }
}

@available(iOS 13.0, *)
private extension TraitRegistryTests {
    class TestTrait: AppcuesExperienceTrait {
        static let type = "@test/trait"

        weak var metadataDelegate: AppcuesTraitMetadataDelegate?

        required init?(configuration: AppcuesExperiencePluginConfiguration) {}
    }
}
