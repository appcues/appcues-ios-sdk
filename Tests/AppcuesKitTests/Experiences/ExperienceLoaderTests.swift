//
//  ExperienceLoaderTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-05-25.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

@available(iOS 13.0, *)
class ExperienceLoaderTests: XCTestCase {

    var appcues: MockAppcues!
    var experienceLoader: ExperienceLoader!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        experienceLoader = ExperienceLoader(container: appcues.container)
    }

    func testLoadPublished() throws {
        // Arrange
        appcues.networking.onGet = { endpoint in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.content(experienceID: "123").url(config: self.appcues.config, storage: self.appcues.storage)
            )
            return .success(Experience.mock)
        }
        appcues.experienceRenderer.onShowExperience = { experience, priority, published, completion in
            XCTAssertEqual(priority, .normal)
            XCTAssertTrue(published)
            completion?(.success(()))
        }

        let completionExpectation = expectation(description: "Completion called")

        // Act
        experienceLoader.load(experienceID: "123", published: true) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testLoadUnpublished() throws {
        // Arrange
        appcues.networking.onGet = { endpoint in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.preview(experienceID: "123").url(config: self.appcues.config, storage: self.appcues.storage)
            )
            return .success(Experience.mock)
        }
        appcues.experienceRenderer.onShowExperience = { experience, priority, published, completion in
            XCTAssertEqual(priority, .normal)
            XCTAssertFalse(published)
            completion?(.success(()))
        }

        let completionExpectation = expectation(description: "Completion called")

        // Act
        experienceLoader.load(experienceID: "123", published: false) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testLoadFail() throws {
        // Arrange
        appcues.networking.onGet = { endpoint in
            return .failure(URLError(.resourceUnavailable))
        }

        let completionExpectation = expectation(description: "Completion called")

        // Act
        experienceLoader.load(experienceID: "123", published: true) { result in
            if case .failure = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }
}
