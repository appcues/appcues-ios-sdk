//
//  Clause.swift
//  Appcues
//
//  Created by Matt on 2025-08-21.
//  Copyright © 2025 Appcues. All rights reserved.
//

import Foundation

internal indirect enum Clause {
    case and([Clause])
    // swiftlint:disable:next identifier_name
    case or([Clause])
    case not(Clause)

    case survey(SurveyClause)
    case token(TokenClause)

    case unknown

    func evaluate(state: ConditionalState) -> Bool {
        switch self {
        case .and(let conditions):
            return conditions.allSatisfy { $0.evaluate(state: state) }
        case .or(let conditions):
            return conditions.contains { $0.evaluate(state: state) }
        case .not(let clause):
            return !clause.evaluate(state: state)

        case .survey(let clause):
            return clause.evaluate(state: state)
        case .token(let clause):
            return clause.evaluate()

        case .unknown:
            return false
        }
    }
}

extension Clause {
    struct SurveyClause: Decodable, CustomStringConvertible {
        let block: UUID
        let `operator`: Operator
        let value: String

        var description: String {
            return "\(block) \(`operator`.description) \(value)"
        }

        func evaluate(state: ConditionalState) -> Bool {
            guard let propertyValue = state[blockID: block] else { return false }
            return `operator`.evaluate(propertyValue, value)
        }
    }

    struct TokenClause: Decodable, CustomStringConvertible {
        let token: String
        let `operator`: Operator
        let value: String

        var description: String {
            return "\(token) \(`operator`.description) \(value)"
        }

        func evaluate() -> Bool {
            return `operator`.evaluate(token, value)
        }
    }

    internal enum Operator: String, Decodable {
        // DEFAULT_OPERATORS
        case equals = "=="
        case doesntEqual = "!="
        case contains = "*"
        case doesntContain = "!*"
        case startsWith = "^"
        case doesntStartWith = "!^"
        case endsWith = "$"
        case doesntEndWith = "!$"
        case matchesRegex = "regex"

        // MULTI_VALUE_OPERATORS
        case isOneOf = "in"
        case isntOneOf = "not in"

        // NUMERIC_OPERATORS
        case isGreaterThan = ">"
        case isGreaterOrEqual = ">="
        case islessThan = "<"
        case isLessOrEqual = "<="

        // swiftlint:disable:next cyclomatic_complexity
        func evaluate(_ lhs: String, _ rhs: String) -> Bool {
            switch self {
            case .equals:
                return lhs == rhs
            case .doesntEqual:
                return lhs != rhs
            case .contains:
                return lhs.contains(rhs)
            case .doesntContain:
                return !lhs.contains(rhs)
            case .startsWith:
                return lhs.hasPrefix(rhs)
            case .doesntStartWith:
                return !lhs.hasPrefix(rhs)
            case .endsWith:
                return lhs.hasSuffix(rhs)
            case .doesntEndWith:
                return !lhs.hasSuffix(rhs)
            case .matchesRegex:
                let range = NSRange(location: 0, length: lhs.utf16.count)
                guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
                return regex.firstMatch(in: lhs, options: [], range: range) != nil
            case .isOneOf:
                return lhs.split(whereSeparator: \.isNewline).contains { $0 == rhs }
            case .isntOneOf:
                return !lhs.split(whereSeparator: \.isNewline).contains { $0 == rhs }
            case .isGreaterThan:
                guard let lhs = Double(lhs), let rhs = Double(rhs) else { return false }
                return Double(lhs) > Double(rhs)
            case .isGreaterOrEqual:
                guard let lhs = Double(lhs), let rhs = Double(rhs) else { return false }
                return Double(lhs) >= Double(rhs)
            case .islessThan:
                guard let lhs = Double(lhs), let rhs = Double(rhs) else { return false }
                return Double(lhs) < Double(rhs)
            case .isLessOrEqual:
                guard let lhs = Double(lhs), let rhs = Double(rhs) else { return false }
                return Double(lhs) <= Double(rhs)
            }
        }
    }
}
// MARK: - Decodable

extension Clause: Decodable {
    private enum ClauseError: Error {
        case unknownClause
    }

    private enum CodingKeys: CodingKey {
        case and
        // swiftlint:disable:next identifier_name
        case or
        case not

        case survey
        case token
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let allKeys = ArraySlice<CodingKeys>(container.allKeys)

            guard let onlyKey = allKeys.first else {
                throw ClauseError.unknownClause
            }

            guard allKeys.count == 1 else {
                throw DecodingError.typeMismatch(Clause.self, DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid number of keys found (\(allKeys.count)), expected one.",
                    underlyingError: nil
                ))
            }

            switch onlyKey {
            case .and:
                self = Clause.and(try container.decode([Clause].self, forKey: .and))
            case .or:
                self = Clause.or(try container.decode([Clause].self, forKey: .or))
            case .not:
                self = Clause.not(try container.decode(Clause.self, forKey: .not))

            case .survey:
                self = Clause.survey(try container.decode(SurveyClause.self, forKey: .survey))
            case .token:
                self = Clause.token(try container.decode(TokenClause.self, forKey: .token))
            }
        } catch is ClauseError {
            self = Clause.unknown
        }
    }
}

// MARK: - CustomStringConvertible

extension Clause: CustomStringConvertible {
    var description: String {
        switch self {
        case .and(let conditions):
            return conditions.map { $0.description }.joined(separator: " AND ")
        case .or(let conditions):
            return conditions.map { $0.description }.joined(separator: " OR ")
        case .not(let clause):
            return "NOT \(clause.description)"

        case .survey(let surveyClause):
            return surveyClause.description
        case .token(let tokenClause):
            return tokenClause.description

        case .unknown:
            return "unknown clause"
        }
    }
}

extension Clause.Operator: CustomStringConvertible {
    var description: String {
        switch self {
        case .equals:
            return "equals"
        case .doesntEqual:
            return "doesn't equal"
        case .contains:
            return "contains"
        case .doesntContain:
            return "doesn't contain"
        case .startsWith:
            return "starts with"
        case .doesntStartWith:
            return "doesn't start with"
        case .endsWith:
            return "ends with"
        case .doesntEndWith:
            return "doesn't end with"
        case .matchesRegex:
            return "matches regex"
        case .isOneOf:
            return "is one of"
        case .isntOneOf:
            return "isn't one of"
        case .isGreaterThan:
            return "is greater than"
        case .isGreaterOrEqual:
            return "is greater than or equal to"
        case .islessThan:
            return "is less than"
        case .isLessOrEqual:
            return "is less than or equal to"
        }
    }
}
