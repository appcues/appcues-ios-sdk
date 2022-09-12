//
//  StepRefTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-02-07.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class StepRefTests: XCTestCase {
    typealias SI = Experience.StepIndex

    func testResolveIndex() throws {
        XCTAssertEqual(
            StepReference.index(0).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 0)),
            SI(group: 0, item: 0)
        )
        XCTAssertEqual(
            StepReference.index(0).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)),
            SI(group: 0, item: 0)
        )
        XCTAssertEqual(
            StepReference.index(0).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 1, item: 1)),
            SI(group: 0, item: 0)
        )
        XCTAssertEqual(
            StepReference.index(3).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)),
            SI(group: 1, item: 0)
        )
        XCTAssertNil(StepReference.index(134).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)))
    }

    func testResolveOffset() throws {
        XCTAssertEqual(
            StepReference.offset(1).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)),
            SI(group: 0, item: 2)
        )
        XCTAssertEqual(
            StepReference.offset(-1).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)),
            SI(group: 0, item: 0)
        )
        XCTAssertEqual(
            StepReference.offset(2).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)),
            SI(group: 1, item: 0)
        )
        XCTAssertEqual(
            StepReference.offset(0).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)),
            SI(group: 0, item: 1)
        )
        XCTAssertNil(StepReference.offset(-10).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 1)))
    }

    func testResolveID() throws {
        XCTAssertEqual(
            StepReference.stepID(UUID(uuidString: "fb529214-3c78-4d6d-ba93-b55d22497ca1")!).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 0)),
            SI(group: 0, item: 0)
        )
        XCTAssertEqual(
            StepReference.stepID(UUID(uuidString: "fb529214-3c78-4d6d-ba93-b55d22497ca1")!).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 1, item: 0)),
            SI(group: 0, item: 0)
        )
        XCTAssertEqual(
            StepReference.stepID(UUID(uuidString: "149f335f-15f6-4d8a-9e38-29a4ca435fd2")!).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 0)),
            SI(group: 0, item: 1)
        )
        XCTAssertEqual(
            StepReference.stepID(UUID(uuidString: "03652bd5-f0cb-44f0-9274-e95b4441d857")!).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 0)),
            SI(group: 1, item: 0)
        )
        XCTAssertNil(StepReference.stepID(UUID(uuidString: "49e21be9-cd9c-4ec6-85de-e4f24a676e31")!).resolve(experience: ExperienceData.mock, currentIndex: SI(group: 0, item: 0)))
    }

    func testEquatable() throws {
        XCTAssertTrue(StepReference.index(1) == StepReference.index(1))
        XCTAssertFalse(StepReference.index(0) == StepReference.index(1))

        XCTAssertTrue(StepReference.offset(1) == StepReference.offset(1))
        XCTAssertFalse(StepReference.offset(0) == StepReference.offset(1))

        XCTAssertTrue(StepReference.stepID(UUID(uuidString: "fb529214-3c78-4d6d-ba93-b55d22497ca1")!) == StepReference.stepID(UUID(uuidString: "fb529214-3c78-4d6d-ba93-b55d22497ca1")!))
        XCTAssertFalse(StepReference.stepID(UUID(uuidString: "fb529214-3c78-4d6d-ba93-b55d22497ca1")!) == StepReference.stepID(UUID(uuidString: "149f335f-15f6-4d8a-9e38-29a4ca435fd2")!))

        XCTAssertFalse(StepReference.index(1) == StepReference.offset(1))
    }
}
