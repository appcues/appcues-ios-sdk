//
//  OneTimeEventDelegateTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-11.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class OneTimeEventDelegateTests: XCTestCase {

    func testCompletionInvokedOnlyOnce() throws {
        var completionCallCount = 0
        let delegate = MulticastDelegate<ExperienceEventDelegate>()

        let instance = ExperienceRenderer.OneTimeEventDelegate(on: .displayedStep, completion: { completionCallCount += 1 })
        delegate.add(instance)

        // Act
        delegate.invoke { $0.lifecycleEvent(.stepStarted(Experience.dummy, 0)) }
        delegate.invoke { $0.lifecycleEvent(.stepStarted(Experience.dummy, 0)) }

        // Assert
        XCTAssertEqual(completionCallCount, 1)
    }

    func testErrorsCallCompletion() throws {
        var completionCallCount = 0
        let delegate = MulticastDelegate<ExperienceEventDelegate>()

        let instance = ExperienceRenderer.OneTimeEventDelegate(on: .displayedStep, completion: { completionCallCount += 1 })
        delegate.add(instance)

        // Act
        delegate.invoke { $0.lifecycleEvent(.stepError(Experience.dummy, 0, "oh no")) }

        // Assert
        XCTAssertEqual(completionCallCount, 1)
    }

}

private extension Experience {
    static var dummy = Experience(id: UUID(), name: "test", traits: [], steps: [])
}
