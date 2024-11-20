//
//  DeepLinkVerifierTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-10-13.
//  Copyright © 2023 Appcues. All rights reserved.
//
 
import XCTest
import Combine
@testable import AppcuesKit

class DeepLinkVerifierTests: XCTestCase {

    var deepLinkVerifier: MockDeepLinkVerifier!

    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        deepLinkVerifier = MockDeepLinkVerifier(applicationID: "app-id")
    }

    @MainActor
    func testSuccess() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        deepLinkVerifier.publisher
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        deepLinkVerifier.mockURLTypes = [["CFBundleURLSchemes": ["appcues-app-id"]]]
        let token = UUID()

        // Act
        deepLinkVerifier.verifyDeepLink(token: token)
        // Simulate link returning
        deepLinkVerifier.receivedVerification(token: token.uuidString)

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and a success one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .verified)
    }

    @MainActor
    func testError0() async throws {
        // Arrange
        deepLinkVerifier = MockDeepLinkVerifier(applicationID: "<unsafe>")

        let expectation = XCTestExpectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        deepLinkVerifier.publisher
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)


        deepLinkVerifier.mockURLTypes = [["CFBundleURLSchemes": ["appcues-<unsafe>"]]]

        // Act
        deepLinkVerifier.verifyDeepLink()

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and an unverified one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .unverified)
        XCTAssertEqual(values[safe: 1]?.subtitle, "Error 0: Failed to set up verification")
    }

    @MainActor
    func testError1() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        deepLinkVerifier.publisher
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)


        deepLinkVerifier.mockURLTypes = nil

        // Act
        deepLinkVerifier.verifyDeepLink()

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and an unverified one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .unverified)
        XCTAssertEqual(values[safe: 1]?.subtitle, "Error 1: CFBundleURLSchemes value missing")
    }

    @MainActor
    func testError2() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        deepLinkVerifier.publisher
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)


        deepLinkVerifier.mockURLTypes = [["CFBundleURLSchemes": ["appcues-app-id"]]]

        // Act
        deepLinkVerifier.verifyDeepLink()
        // Simulate link NOT returning
        // deepLinkVerifier.receivedVerification(token: token.uuidString)

        // Assert
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(values.count, 2, "a pending value and an unverified one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .unverified)
        XCTAssertEqual(values[safe: 1]?.subtitle, "Error 2: Appcues SDK not receiving links")
    }

    @MainActor
    func testError3() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        deepLinkVerifier.publisher
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)


        deepLinkVerifier.mockURLTypes = [["CFBundleURLSchemes": ["appcues-app-id"]]]

        // Act
        deepLinkVerifier.verifyDeepLink()
        // Simulate link returning an unexpected token value
        deepLinkVerifier.receivedVerification(token: "some-random-value")

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and an unverified one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .unverified)
        XCTAssertEqual(values[safe: 1]?.subtitle, "Error 3: Unexpected result")
    }
}

/// Mock DeepLinkVerifier that allows overriding loading the CFBundleURLSchemes values from the Info.plist
class MockDeepLinkVerifier: DeepLinkVerifier {
    var mockURLTypes: [[String : Any]]?

    override var urlTypes: [[String : Any]]? {
        mockURLTypes
    }
}
