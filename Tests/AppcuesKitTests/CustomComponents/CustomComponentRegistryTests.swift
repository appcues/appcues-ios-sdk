//
//  CustomComponentRegistryTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2025-11-05.
//  Copyright © 2025 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class CustomComponentRegistryTests: XCTestCase {

    var appcues: MockAppcues!
    var customComponentRegistry: CustomComponentRegistry!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        customComponentRegistry = CustomComponentRegistry()
    }

    func testRegister() throws {
        // Arrange
        let model = ExperienceComponent.CustomComponentModel(
            id: UUID(),
            identifier: "test-component",
            configDecoder: MockPluginDecoder(),
            style: nil
        )

        // Act
        customComponentRegistry.registerCustomComponent(identifier: "test-component", type: TestCustomComponent.self)

        // Assert
        let componentData = customComponentRegistry.customComponent(
            for: model,
            renderContext: .modal,
            appcuesInstance: appcues
        )
        XCTAssertNotNil(componentData)
        XCTAssertTrue(componentData?.type === TestCustomComponent.self)
    }

    func testUnknownComponent() throws {
        // Arrange
        let model = ExperienceComponent.CustomComponentModel(
            id: UUID(),
            identifier: "unknown-component",
            configDecoder: MockPluginDecoder(),
            style: nil
        )

        // Act
        customComponentRegistry.registerCustomComponent(identifier: "test-component", type: TestCustomComponent.self)

        // Assert
        let componentData = customComponentRegistry.customComponent(
            for: model,
            renderContext: .modal,
            appcuesInstance: appcues
        )
        XCTAssertNil(componentData)
    }

    func testDuplicateRegistrations() throws {
        // Arrange
        let model = ExperienceComponent.CustomComponentModel(
            id: UUID(),
            identifier: "test-component",
            configDecoder: MockPluginDecoder(),
            style: nil
        )

        // Act
        customComponentRegistry.registerCustomComponent(identifier: "test-component", type: TestCustomComponent.self)
        customComponentRegistry.registerCustomComponent(identifier: "test-component", type: TestCustomComponent2.self)

        // Assert
        // Duplicate registrations should overwrite the previous one
        let componentData = customComponentRegistry.customComponent(
            for: model,
            renderContext: .modal,
            appcuesInstance: appcues
        )
        XCTAssertNotNil(componentData)
        XCTAssertTrue(componentData?.type === TestCustomComponent2.self)
    }

    func testComponentDebugInfo() throws {
        // Arrange
        customComponentRegistry.registerCustomComponent(identifier: "component-a", type: TestCustomComponent.self)
        customComponentRegistry.registerCustomComponent(identifier: "component-b", type: TestCustomComponent2.self)
        customComponentRegistry.registerCustomComponent(identifier: "component-c", type: TestCustomComponentWithDebug.self)

        // Act
        let debugInfo = customComponentRegistry.componentDebugInfo

        // Assert
        XCTAssertEqual(debugInfo.count, 3)
        // Should be sorted by identifier
        XCTAssertEqual(debugInfo[0].identifier, "component-a")
        XCTAssertEqual(debugInfo[1].identifier, "component-b")
        XCTAssertEqual(debugInfo[2].identifier, "component-c")
        
        // Check debug config values
        XCTAssertNil(debugInfo[0].debuggableConfig)
        XCTAssertNil(debugInfo[1].debuggableConfig)
        XCTAssertNotNil(debugInfo[2].debuggableConfig)
        XCTAssertEqual(debugInfo[2].debuggableConfig?["testKey"] as? String, "testValue")
    }

    func testCustomComponentData() throws {
        // Arrange
        let model = ExperienceComponent.CustomComponentModel(
            id: UUID(),
            identifier: "test-component",
            configDecoder: MockPluginDecoder(),
            style: nil
        )
        customComponentRegistry.registerCustomComponent(identifier: "test-component", type: TestCustomComponent.self)

        // Act
        let componentData = customComponentRegistry.customComponent(
            for: model,
            renderContext: .modal,
            appcuesInstance: appcues
        )

        // Assert
        XCTAssertNotNil(componentData)
        XCTAssertTrue(componentData?.type === TestCustomComponent.self)
        XCTAssertNotNil(componentData?.config)
        XCTAssertEqual(componentData?.config.level, .step)
        XCTAssertEqual(componentData?.config.renderContext, .modal)
        XCTAssertNotNil(componentData?.actionController)
    }
}

@available(iOS 13.0, *)
private extension CustomComponentRegistryTests {
    class MockPluginDecoder: PluginDecoder {
        func decode<T: Decodable>(_ type: T.Type) -> T? {
            return nil
        }
    }

    class TestCustomComponent: UIViewController, AppcuesCustomComponentViewController {
        required init?(configuration: AppcuesExperiencePluginConfiguration, actionController: AppcuesExperienceActions) {
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class TestCustomComponent2: UIViewController, AppcuesCustomComponentViewController {
        required init?(configuration: AppcuesExperiencePluginConfiguration, actionController: AppcuesExperienceActions) {
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class TestCustomComponentWithDebug: UIViewController, AppcuesCustomComponentViewController {
        static var debugConfig: [String: Any]? {
            ["testKey": "testValue"]
        }

        required init?(configuration: AppcuesExperiencePluginConfiguration, actionController: AppcuesExperienceActions) {
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
