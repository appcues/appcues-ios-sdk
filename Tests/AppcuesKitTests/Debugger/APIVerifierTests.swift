//
//  APIVerifierTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-10-13.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
import Combine
@testable import AppcuesKit

class APIVerifierTests: XCTestCase {

    var apiVerifier: APIVerifier!
    var networking: MockNetworking!

    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        networking = MockNetworking()
        apiVerifier = APIVerifier(networking: networking)
    }

    @MainActor
    func testSuccess() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        apiVerifier.publisher
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        networking.onGet = { endpoint, _ in
            ActivityResponse(ok: true)
        }

        // Act
        await apiVerifier.verifyAPI()

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and a success one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .verified)
    }

    @MainActor
    func testFailure() async throws {
        // Arrange
        let expectation = expectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        apiVerifier.publisher
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        networking.onGet = { endpoint, _ in
            throw NetworkingError.nonSuccessfulStatusCode(500, nil)
        }

        // Act
        await apiVerifier.verifyAPI()

        // Assert
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and an unverified one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .unverified)
    }
}
