//
//  XCTest+Async.swift
//  Appcues
//
//  Created by Matt on 2025-07-16.
//  Copyright © 2025 Appcues. All rights reserved.
//

import XCTest

extension XCTest {
    func XCTAssertThrowsErrorAsync<T: Sendable>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (_ error: Error) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
