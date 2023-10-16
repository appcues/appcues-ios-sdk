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

@available(iOS 13.0, *)
class APIVerifierTests: XCTestCase {

    var apiVerifier: APIVerifier!
    var networking: MockNetworking!

    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        networking = MockNetworking()
        apiVerifier = APIVerifier(networking: networking)
    }

    func testSuccess() throws {
        // Arrange
        let expectation = XCTestExpectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        apiVerifier.subject
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        networking.onGet = { endpoint, _ in
            return .success(ActivityResponse(ok: true))
        }

        // Act
        apiVerifier.verifyAPI()

        // Assert
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and a success one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .verified)
    }

    func testFailure() throws {
        // Arrange
        let expectation = expectation(description: "Publishes values then finishes")
        var values: [StatusItem] = []

        apiVerifier.subject
            .sink {
                values.append($0)
                if values.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        networking.onGet = { endpoint, _ in
            return .failure(NetworkingError.nonSuccessfulStatusCode(500))
        }

        // Act
        apiVerifier.verifyAPI()

        // Assert
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(values.count, 2, "a pending value and a success one")
        XCTAssertEqual(values[safe: 0]?.status, .pending)
        XCTAssertEqual(values[safe: 1]?.status, .unverified)
    }
}
