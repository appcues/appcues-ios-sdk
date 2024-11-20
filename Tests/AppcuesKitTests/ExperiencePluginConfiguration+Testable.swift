//
//  ExperiencePluginConfiguration+Testable.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-12-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
import XCTest
@testable import AppcuesKit

extension AppcuesExperiencePluginConfiguration {
    convenience init(_ config: Any?, level: Level = .step, context: RenderContext = .modal, appcues: Appcues? = nil) {
        self.init(FakePluginDecoder(config), level: level, renderContext: context, appcues: appcues)
    }
}

struct FakePluginDecoder: PluginDecoder {
    private let value: Any?

    init(_ value: Any?) {
        self.value = value
    }

    func decode<T>(_ type: T.Type) -> T? where T : Decodable {
        guard let value = value else { return nil }
        guard let castValue = value as? T else {
            fatalError("uh oh \(type): \(value)")
        }
        return castValue
    }
}

// XCTestExpectation isn't Decodable, so fake it with this wrapper that stores the expectation in a static var to "decode" from
struct DecodableExpectation: Decodable {
    private static var expectationStore: [UUID: XCTestExpectation] = [:]

    let expectation: XCTestExpectation
    private let expectationID: UUID

    init?(expectation: XCTestExpectation?) {
        guard let expectation = expectation else { return nil }
        self.expectation = expectation
        self.expectationID = UUID()
        Self.expectationStore[expectationID] = expectation
    }

    enum CodingKeys: CodingKey {
        case expectationID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.expectationID = try container.decode(UUID.self, forKey: .expectationID)
        if let expectation = Self.expectationStore[expectationID] {
            self.expectation = expectation
        } else {
            throw DecodingError.valueNotFound(XCTestExpectation.self, .init(codingPath: [], debugDescription: "cant find expectation"))
        }
    }
}

/// Asserts that an asynchronous expression throws an error.
/// (Intended to function as a drop-in asynchronous version of `XCTAssertThrowsError`.)
///
/// Example usage:
///
///     await assertThrowsAsyncError(
///         try await sut.function()
///     ) { error in
///         XCTAssertEqual(error as? MyError, MyError.specificError)
///     }
///
/// - Parameters:
///   - expression: An asynchronous expression that can throw an error.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs.
///     The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs.
///     The default is the line number where you call this function.
///   - errorHandler: An optional handler for errors that expression throws.
func XCTAssertThrowsAsyncError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        // expected error to be thrown, but it was not
        let customMessage = message()
        if customMessage.isEmpty {
            XCTFail("Asynchronous call did not throw an error.", file: file, line: line)
        } else {
            XCTFail(customMessage, file: file, line: line)
        }
    } catch {
        errorHandler(error)
    }
}
