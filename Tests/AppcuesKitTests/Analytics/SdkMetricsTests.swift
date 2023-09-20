//
//  SdkMetricsTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-02-09.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class SdkMetricsTests: XCTestCase {

    func testThreadSafety() throws {
        // Arrange
        let dispatchGroup = DispatchGroup()
        let completeExpectation = expectation(description: "multi thread")
        completeExpectation.expectedFulfillmentCount = 100

        let ids = (0..<20).map({ _ in UUID() })
        var results: [[String: Any]] = []

        // Act
        // Process activity on 100 threads
        for i in 0..<100 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let idIndex = Int(floor(Double(i)/5))
                switch i % 5 {
                case 0: SdkMetrics.tracked(ids[idIndex], time: Date())
                case 1: SdkMetrics.requested(ids[idIndex])
                case 2: SdkMetrics.responded(ids[idIndex])
                case 3: SdkMetrics.renderStart(ids[idIndex])
                // Note that technically the write to results isn't thread safe, but if the test crashes here, that's ok
                case 4: results.append(SdkMetrics.trackRender(ids[idIndex]))
                default: XCTFail()
                }
                completeExpectation.fulfill()
                dispatchGroup.leave()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }
}
