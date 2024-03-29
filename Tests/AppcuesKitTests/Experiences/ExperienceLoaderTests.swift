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
        appcues.networking.onGet = { endpoint, authorization, completion in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.content(experienceID: "123").url(config: self.appcues.config, storage: self.appcues.storage)
            )
            completion(.success(Experience.mock))
        }
        appcues.experienceRenderer.onProcessAndShowExperience = { experience, completion in
            XCTAssertEqual(experience.priority, .normal)
            XCTAssertTrue(experience.published)
            guard case .showCall = experience.trigger else { return XCTFail() }
            completion?(.success(()))
        }

        let completionExpectation = expectation(description: "Completion called")

        // Act
        experienceLoader.load(experienceID: "123", published: true, queryItems: [], trigger: .showCall) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testLoadUnpublished() throws {
        // Arrange
        appcues.networking.onGet = { endpoint, authorization, completion in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.preview(experienceID: "123", queryItems: [URLQueryItem(name: "query", value: "xyz")]).url(config: self.appcues.config, storage: self.appcues.storage)
            )
            completion(.success(Experience.mock))
        }
        appcues.experienceRenderer.onProcessAndShowExperience = { experience, completion in
            XCTAssertEqual(experience.priority, .normal)
            XCTAssertFalse(experience.published)
            guard case .preview = experience.trigger else { return XCTFail() }
            completion?(.success(()))
        }

        let completionExpectation = expectation(description: "Completion called")

        // Act
        experienceLoader.load(experienceID: "123", published: false, queryItems: [URLQueryItem(name: "query", value: "xyz")], trigger: .preview) { result in
            if case .success = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testLoadFail() throws {
        // Arrange
        appcues.networking.onGet = { endpoint, authorization, completion in
            completion(.failure(URLError(.resourceUnavailable)))
        }

        let completionExpectation = expectation(description: "Completion called")

        // Act
        experienceLoader.load(experienceID: "123", published: true, queryItems: [], trigger: .showCall) { result in
            if case .failure = result {
                completionExpectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testReloadPreviewNotification() throws {
        // Arrange
        let reloadExpectation = expectation(description: "Data loaded called")

        // Load the initial preview
        experienceLoader.load(experienceID: "123", published: false, queryItems: [], trigger: .preview, completion: nil)

        appcues.networking.onGet = { endpoint, authorization, completion in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.preview(experienceID: "123").url(config: self.appcues.config, storage: self.appcues.storage)
            )
            reloadExpectation.fulfill()

            completion(.success(Experience.mock))
        }

        // Act
        appcues.container.resolve(NotificationCenter.self).post(name: .shakeToRefresh, object: nil)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testNoOpWhenNotificationOnPublishedExperience() throws {
        // Arrange
        let reloadExpectation = expectation(description: "Data loaded called")
        reloadExpectation.isInverted = true

        // Load the initial preview
        experienceLoader.load(experienceID: "123", published: false, queryItems: [], trigger: .preview, completion: nil)
        // Load a published experience
        experienceLoader.load(experienceID: "abc", published: true, queryItems: [], trigger: .preview, completion: nil)

        appcues.networking.onGet = { endpoint, authorization, completion in
            reloadExpectation.fulfill()
            XCTFail("Experience should not be loaded on notification")
        }

        // Act
        appcues.container.resolve(NotificationCenter.self).post(name: .shakeToRefresh, object: nil)

        // Assert
        waitForExpectations(timeout: 1)
    }
}
