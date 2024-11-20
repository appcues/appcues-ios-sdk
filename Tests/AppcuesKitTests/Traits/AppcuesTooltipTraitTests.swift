//
//  AppcuesTooltipTraitTests.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 9/13/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesTooltipTraitTests: XCTestCase {

    func testBackdrop() throws {
        // Arrange
        let containerController = DefaultContainerViewController(
            stepControllers: [],
            pageMonitor: AppcuesExperiencePageMonitor(numberOfPages: 0, currentPage: 0)
        )
        let trait = try XCTUnwrap(AppcuesTooltipTrait())
        let wrapper = try trait.createWrapper(around: containerController)

        // Act
        let backdrop = trait.getBackdrop(for: wrapper)

        // Assert
        XCTAssertNotNil(backdrop)
    }
}

extension AppcuesTooltipTrait {
    convenience init?() {
        self.init(
            configuration: AppcuesExperiencePluginConfiguration(
                AppcuesTooltipTrait.Config(hidePointer: nil, pointerBase: nil, pointerLength: nil, pointerCornerRadius: nil, style: nil)
            )
        )
    }
}
