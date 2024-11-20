//
//  ContentLoaderTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-05-25.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ContentLoaderTests: XCTestCase {

    var appcues: MockAppcues!
    var contentLoader: ContentLoader!

    override func setUpWithError() throws {
        appcues = MockAppcues()
        contentLoader = ContentLoader(container: appcues.container)
    }

    func testLoadPublished() async throws {
        // Arrange
        appcues.networking.onGet = { endpoint, authorization in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.content(experienceID: "123").url(config: self.appcues.config, storage: self.appcues.storage)
            )
            return Experience.mock
        }
        appcues.experienceRenderer.onProcessAndShowExperience = { experience in
            XCTAssertEqual(experience.priority, .normal)
            XCTAssertTrue(experience.published)
            guard case .showCall = experience.trigger else { return XCTFail() }
        }

        // Act
        try await contentLoader.load(experienceID: "123", published: true, queryItems: [], trigger: .showCall)
    }

    func testLoadUnpublished() async throws {
        // Arrange
        appcues.networking.onGet = { endpoint, authorization in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.preview(experienceID: "123", queryItems: [URLQueryItem(name: "query", value: "xyz")]).url(config: self.appcues.config, storage: self.appcues.storage)
            )
            return Experience.mock
        }
        appcues.experienceRenderer.onProcessAndShowExperience = { experience in
            XCTAssertEqual(experience.priority, .normal)
            XCTAssertFalse(experience.published)
            guard case .preview = experience.trigger else { return XCTFail() }
        }

        // Act
        try await contentLoader.load(experienceID: "123", published: false, queryItems: [URLQueryItem(name: "query", value: "xyz")], trigger: .preview)
    }

    func testLoadFail() async throws {
        // Arrange
        appcues.networking.onGet = { endpoint, authorization in
            throw URLError(.resourceUnavailable)
        }

        // Act/Assert
        await XCTAssertThrowsAsyncError(try await contentLoader.load(experienceID: "123", published: true, queryItems: [], trigger: .showCall)) {
            XCTAssertEqual(($0 as? URLError), URLError(.resourceUnavailable))
        }
    }

    func testReloadPreviewNotification() async throws {
        // Arrange
        let reloadExpectation = expectation(description: "Data loaded called")

        // Load the initial preview
        appcues.networking.onGet = { _, _ in Experience.mock}
        try await contentLoader.load(experienceID: "123", published: false, queryItems: [], trigger: .preview)

        appcues.networking.onGet = { endpoint, authorization in
            XCTAssertEqual(
                endpoint.url(config: self.appcues.config, storage: self.appcues.storage),
                APIEndpoint.preview(experienceID: "123").url(config: self.appcues.config, storage: self.appcues.storage)
            )
            reloadExpectation.fulfill()

            return Experience.mock
        }

        // Act
        appcues.container.resolve(NotificationCenter.self).post(name: .shakeToRefresh, object: nil)

        // Assert
        await fulfillment(of: [reloadExpectation], timeout: 1)
    }

    func testNoOpWhenNotificationOnPublishedExperience() async throws {
        // Arrange
        let reloadExpectation = expectation(description: "Data loaded called")
        reloadExpectation.isInverted = true

        // Load the initial preview
        appcues.networking.onGet = { _, _ in Experience.mock}
        try await contentLoader.load(experienceID: "123", published: false, queryItems: [], trigger: .preview)
        // Load a published experience
        try await contentLoader.load(experienceID: "abc", published: true, queryItems: [], trigger: .preview)

        appcues.networking.onGet = { endpoint, authorization in
            reloadExpectation.fulfill()
            XCTFail("Experience should not be loaded on notification")
            return false
        }

        // Act
        appcues.container.resolve(NotificationCenter.self).post(name: .shakeToRefresh, object: nil)

        // Assert
        await fulfillment(of: [reloadExpectation], timeout: 1)
    }

    func testPushRequestEncode() throws {
        // Arrange
        let model = PushRequest(
            deviceID: "<device-id>",
            queryItems: [
                URLQueryItem(name: "locale_id", value: "<some-id>"),
                URLQueryItem(name: "test", value: nil), // expected to be skipped
                URLQueryItem(name: "device_id", value: "BAD") // expected to be overwritten
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        // Act
        let encoded = try encoder.encode(model)

        // Assert
        XCTAssertEqual(String(data: encoded, encoding: .utf8), "{\"device_id\":\"<device-id>\",\"locale_id\":\"<some-id>\"}")
    }
}
