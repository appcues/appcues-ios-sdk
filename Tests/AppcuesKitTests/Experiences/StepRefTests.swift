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

    func testResolveIndex() throws {
        XCTAssertEqual(StepReference.index(0).resolve(experience: Experience.mock, currentIndex: 0), 0)
        XCTAssertEqual(StepReference.index(0).resolve(experience: Experience.mock, currentIndex: 1), 0)
        XCTAssertEqual(StepReference.index(3).resolve(experience: Experience.mock, currentIndex: 1), 3)
        XCTAssertEqual(StepReference.index(134).resolve(experience: Experience.mock, currentIndex: 1), 134)
    }

    func testResolveOffset() throws {
        XCTAssertEqual(StepReference.offset(1).resolve(experience: Experience.mock, currentIndex: 1), 2)
        XCTAssertEqual(StepReference.offset(-1).resolve(experience: Experience.mock, currentIndex: 1), 0)
        XCTAssertEqual(StepReference.offset(0).resolve(experience: Experience.mock, currentIndex: 1), 1)
        XCTAssertEqual(StepReference.offset(-10).resolve(experience: Experience.mock, currentIndex: 1), -9)
    }

    func testResolveID() throws {
        XCTAssertEqual(StepReference.stepID(UUID(uuidString: "fb529214-3c78-4d6d-ba93-b55d22497ca1")!).resolve(experience: Experience.mock, currentIndex: 0), 0)
        XCTAssertEqual(StepReference.stepID(UUID(uuidString: "fb529214-3c78-4d6d-ba93-b55d22497ca1")!).resolve(experience: Experience.mock, currentIndex: 3), 0)
        XCTAssertEqual(StepReference.stepID(UUID(uuidString: "149f335f-15f6-4d8a-9e38-29a4ca435fd2")!).resolve(experience: Experience.mock, currentIndex: 0), 2)
        XCTAssertEqual(StepReference.stepID(UUID(uuidString: "49e21be9-cd9c-4ec6-85de-e4f24a676e31")!).resolve(experience: Experience.mock, currentIndex: 1), -1)
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

private extension Experience {
    static var mock: Experience {
        Experience(
            id: UUID(),
            name: "test",
            traits: [],
            steps: [
                Experience.Step(fixedID: "fb529214-3c78-4d6d-ba93-b55d22497ca1"),
                Experience.Step(fixedID: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                Experience.Step(fixedID: "149f335f-15f6-4d8a-9e38-29a4ca435fd2"),
                Experience.Step(fixedID: "03652bd5-f0cb-44f0-9274-e95b4441d857")
            ])
    }
}

extension Experience.Step {
    init(fixedID: String) {
        self.init(
            id: UUID(uuidString: fixedID) ?? UUID(),
            contentType: "application/json",
            content: ExperienceComponent.spacer(ExperienceComponent.SpacerModel(id: UUID(), spacing: nil, style: nil)),
            traits: [],
            actions: [:])
    }
}
