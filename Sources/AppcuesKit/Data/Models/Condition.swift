//
//  Condition.swift
//  AppcuesKit
//
//  Created by Matt on 2023-06-28.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal struct Conditional<T: Decodable>: Decodable {
    let conditions: Condition
    let data: T

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        var dataKeys = ArraySlice(container.allKeys.filter { $0.stringValue != "conditions" })

        guard let dataKey = dataKeys.popFirst(), dataKeys.isEmpty else {
            throw DecodingError.typeMismatch(Conditional<T>.self, DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Invalid number of non-condition keys found, expected one.",
                underlyingError: nil
            ))
        }

        self.conditions = try container.decode(Condition.self, forKey: DynamicCodingKeys(key: "conditions"))
        self.data = try container.decode(T.self, forKey: dataKey)
    }
}

internal indirect enum Condition {
    case and([Condition])
    // swiftlint:disable:next identifier_name
    case or([Condition])
    case not(Clause)
    case clause(Clause)

    func evaluate(state: State) -> Bool {
        switch self {
        case .and(let conditions):
            return conditions.allSatisfy { $0.evaluate(state: state) }
        case .or(let conditions):
            return conditions.contains { $0.evaluate(state: state) }
        case .not(let clause):
            return !clause.evaluate(state: state)
        case .clause(let clause):
            return clause.evaluate(state: state)
        }
    }
}

extension Condition {
    enum Clause {
        case properties(property: String, Operator, value: String)
        case form(key: UUID, Operator, value: String)

        func evaluate(state: State) -> Bool {
            switch self {
            case let .properties(property, `operator`, value):
                guard let propertyValue = state[property: property] else { return false }
                return `operator`.evaluate(propertyValue, value)
            case let .form(key, `operator`, value):
                guard let formValue = state[formValue: key] else { return false }
                return `operator`.evaluate(formValue, value)
            }
        }
    }

    enum Operator: String, Decodable {
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

        // EXISTENTIAL_OPERATORS
        // EXISTS: { label: 'exists', value: '?' },
        // DOESNT_EXIST: { label: "doesn't exist", value: '!?' },

        // NUMERIC_OPERATORS
        // IS_GREATER_THAN: { label: 'is greater than', value: '>' },
        // IS_GREATER_OR_EQUAL: { label: 'greater than or equal to', value: '>=' },
        // IS_LESS_THAN: { label: 'is less than', value: '<' },
        // IS_LESS_OR_EQUAL: { label: 'less than or equal to', value: '<=' },

        // RELATIVE_TIME_OPERATORS
        // OCCURRED_MORE_THAN: { label: 'occurred more than', value: '> ago' },
        // OCCURRED_LESS_THAN: { label: 'occurred less than', value: '< ago' },
        // OCCURRED_IN_THE_LAST: { label: 'occurred in the last', value: 'within' },

        // ABSOLUTE_TIME_OPERATORS
        // OCCURRED_BEFORE: { label: 'occurred before', value: '< time' },
        // OCCURRED_AFTER: { label: 'occurred after', value: '> time' },

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
            }
        }
    }

    struct State {
        let properties: [String: Any]
        let formValues: [UUID: String]?

        subscript (property key: String) -> String? {
            return properties[key] as? String
        }

        subscript (formValue key: UUID) -> String? {
            return formValues?[key]
        }
    }
}

// MARK: - Decodable

extension Condition: Decodable {
    private enum CodingKeys: CodingKey {
        case and
        // swiftlint:disable:next identifier_name
        case or
        case not
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allKeys = ArraySlice<CodingKeys>(container.allKeys)

        // If no and/or/not key is found, try decoding a leaf clause instead
        guard let onlyKey = allKeys.popFirst() else {
            self = .clause(try Clause(from: decoder))
            return
        }

        guard allKeys.isEmpty else {
            throw DecodingError.typeMismatch(Condition.self, DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Invalid number of keys found, expected one.",
                underlyingError: nil
            ))
        }

        switch onlyKey {
        case .and:
            self = Condition.and(try container.decode([Condition].self, forKey: .and))
        case .or:
            self = Condition.or(try container.decode([Condition].self, forKey: .or))
        case .not:
            self = Condition.not(try container.decode(Condition.Clause.self, forKey: .not))
        }
    }
}

extension Condition.Clause: Decodable {
    private enum CodingKeys: CodingKey {
        case properties
        case form
        // .app, .screen, etc
    }

    private enum ExpressionCodingKeys: CodingKey {
        case property, key
        case `operator`
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allKeys = ArraySlice<CodingKeys>(container.allKeys)

        guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
            throw DecodingError.typeMismatch(Condition.self, DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Invalid number of keys found, expected one.",
                underlyingError: nil
            ))
        }

        switch onlyKey {
        case .properties:
            let nestedContainer = try container.nestedContainer(keyedBy: ExpressionCodingKeys.self, forKey: .properties)

            self = .properties(
                property: try nestedContainer.decode(String.self, forKey: .property),
                try nestedContainer.decode(Condition.Operator.self, forKey: .operator),
                value: try nestedContainer.decode(String.self, forKey: .value)
            )
        case .form:
            let nestedContainer = try container.nestedContainer(keyedBy: ExpressionCodingKeys.self, forKey: .form)

            self = .form(
                key: try nestedContainer.decode(UUID.self, forKey: .key),
                try nestedContainer.decode(Condition.Operator.self, forKey: .operator),
                value: try nestedContainer.decode(String.self, forKey: .value)
            )
        }
    }
}

// MARK: - CustomStringConvertible

extension Condition: CustomStringConvertible {
    var description: String {
        switch self {
        case .and(let conditions):
            return conditions.map { $0.description }.joined(separator: " AND ")
        case .or(let conditions):
            return conditions.map { $0.description }.joined(separator: " OR ")
        case .not(let clause):
            return "NOT \(clause.description)"
        case .clause(let clause):
            return clause.description
        }
    }
}

extension Condition.Clause: CustomStringConvertible {
    var description: String {
        switch self {
        case let .properties(property, `operator`, value):
            return "\(property) \(`operator`.description) \(value)"
        case let .form(key, `operator`, value):
            return "formKey(\(key)) \(`operator`.description) \(value)"
        }
    }
}

extension Condition.Operator: CustomStringConvertible {
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
        }
    }
}
