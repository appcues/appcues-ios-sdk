//
//  NetworkClientTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-10-17.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class NetworkClientTests: XCTestCase {

    var networkClient: NetworkClient!
    var appcues: MockAppcues!
    var delegate: MockAnalyticsDelegate!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)

        let config = Appcues.Config(accountID: "00000", applicationID: "abc")
            .urlSession(urlSession)

        appcues = MockAppcues(config: config)
        delegate = MockAnalyticsDelegate()
        networkClient = NetworkClient(container: appcues.container)
        appcues.analyticsDelegate = delegate
    }

    func testEncodeDates() throws {
        // Arrange
        let date = Date(timeIntervalSince1970: 1666020777)

        // Act
        let encoded = try NetworkClient.encoder.encode(date)

        // Assert
        let string = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(string, "1666020777000", "timestamp formatted in milliseconds with no decimal")
    }


    func testGetSuccess() throws {
        // Arrange
        let expectation = expectation(description: "Request complete")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.appcues.net/healthz")
            XCTAssertNil(request.httpBody)

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, try JSONEncoder().encode(true))
        }

        // Act
        networkClient.get(from: APIEndpoint.health, authorization: nil) { (result: Result<Bool, Error>) in
            if case .success = result {
                expectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testPostSuccess() throws {
        // Arrange
        let expectation = expectation(description: "Request complete")
        MockURLProtocol.requestHandler = { request in   
            XCTAssertEqual(request.url?.absoluteString, "https://api.appcues.net/v1/accounts/00000/users/test/activity")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, try NetworkClient.encoder.encode(true))
        }
        let model = Activity(
            accountID: "00000",
            userID: "test",
            events: [Event(screen: "my screen")])

        // Act
        let data = try NetworkClient.encoder.encode(model)
        networkClient.post(to: APIEndpoint.activity(userID: "test"), authorization: nil, body: data, requestId: nil) { (result: Result<Bool, Error>) in
            if case .success = result {
                expectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testPostAuthorization() throws {
        // Arrange
        let userSignature = "abc"
        let expectation = expectation(description: "Request complete")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(userSignature)")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, try NetworkClient.encoder.encode(true))
        }
        let model = Activity(
            accountID: "00000",
            userID: "test",
            events: [Event(screen: "my screen")])

        // Act
        let data = try NetworkClient.encoder.encode(model)
        networkClient.post(to: APIEndpoint.activity(userID: "test"),
                           authorization: .bearer(userSignature),
                           body: data,
                           requestId: nil) { (result: Result<Bool, Error>) in
            expectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testGetAuthorization() throws {
        // Arrange
        let userSignature = "abc"
        let expectation = expectation(description: "Request complete")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(userSignature)")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, try JSONEncoder().encode(true))
        }

        // Act
        networkClient.get(from: APIEndpoint.health, authorization: .bearer(userSignature)) { (result: Result<Bool, Error>) in
            expectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 1)
    }

}

private class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        do {
            // Call handler with received request and capture the tuple of response and data.
            let (response, data) = try MockURLProtocol.requestHandler!(request)

            // Send received response to the client.
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                // Send received data to the client.
                client?.urlProtocol(self, didLoad: data)
            }

            // Notify request has been finished.
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            // Notify received error.
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
      // This is called if the request gets canceled or completed.
    }
}
