//
//  DebugLogger.swift
//  AppcuesKit
//
//  Created by Matt on 2023-10-25.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal class DebugLogger: ObservableObject, Logging {
    let previousLogger: Logging?

    @Published var log: [Log] = []

    init(previousLogger: Logging?) {
        self.previousLogger = previousLogger
    }

    func stringEncoded() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(log.reversed()) else {
            return "Encoding error"
        }

        return String(data: encoded, encoding: .utf8) ?? "Error"
    }

    func debug(_ message: StaticString, _ args: CVarArg...) {
        previousLogger?.debug(message, args)
        log(message, type: .debug, args)
    }

    func info(_ message: StaticString, _ args: CVarArg...) {
        previousLogger?.info(message, args)
        log(message, type: .info, args)
    }

    func log(_ message: StaticString, _ args: CVarArg...) {
        previousLogger?.log(message, args)
        log(message, type: .log, args)
    }

    func error(_ message: StaticString, _ args: CVarArg...) {
        previousLogger?.error(message, args)
        log(message, type: .error, args)
    }

    func fault(_ message: StaticString, _ args: CVarArg...) {
        previousLogger?.fault(message, args)
        log(message, type: .fault, args)
    }

    private func log(_ message: StaticString, type: Level, _ args: [CVarArg]) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.log(message, type: type, args) }
            return
        }

        // Convert the os_log StaticString to a normal format String
        let normalizedMessage = message.description
            .replacingOccurrences(of: "{public}", with: "")
            .replacingOccurrences(of: "{private}", with: "")
        let item = Log(
            level: type,
            message: String(format: normalizedMessage, args)
        )

        log.append(item)
    }
}

@available(iOS 13.0, *)
extension DebugLogger {
    struct Log: Identifiable, Encodable {
        let id = UUID()
        let timestamp = Date()
        let level: Level
        let message: String

        enum CodingKeys: CodingKey {
            case timestamp, level, message
        }

        // Skip encoding id since the value is meaningless
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(self.timestamp, forKey: .timestamp)
            try container.encode(self.level, forKey: .level)
            try container.encode(self.message, forKey: .message)
        }
    }

    enum Level: String, Encodable, CaseIterable {
        case debug, info, log, error, fault

        var description: String {
            switch self {
            case .debug: return "Debug"
            case .info: return "Info"
            case .log: return "Log"
            case .error: return "Error"
            case .fault: return "Fault"
            }
        }

        var color: Color {
            switch self {
            case .debug, .info: return .secondary
            case .log: return .primary
            case .error, .fault: return .red
            }
        }
    }
}
