//
//  ClauseTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2025-01-27.
//  Copyright © 2025 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ClauseTests: XCTestCase {

    // MARK: - And Clause

    func testAndClause() {
        let andClause = Clause.and([
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "premium")),
            .token(Clause.TokenClause(token: "active", operator: .equals, value: "active"))
        ])

        XCTAssertTrue(andClause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(andClause.description, "premium equals premium AND active equals active")
    }

    func testAndClauseWithFalseCondition() {
        let andClause = Clause.and([
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "premium")),
            .token(Clause.TokenClause(token: "active", operator: .equals, value: "wrong_value"))
        ])
        
        XCTAssertFalse(andClause.evaluate(state: ConditionalState(formState: [:])))
    }
    
    func testSingleAnd() {
        let andClause = Clause.and([
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "premium")),
        ])

        XCTAssertTrue(andClause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(andClause.description, "premium equals premium")
    }

    func testEmptyAndClause() {
        let andClause = Clause.and([])
        let state = ConditionalState(formState: [:])

        // Empty AND clause should evaluate to true (all conditions are satisfied)
        XCTAssertTrue(andClause.evaluate(state: state))
        XCTAssertEqual(andClause.description, "")
    }

    // MARK: - Or Clause

    func testOrClause() {
        let orClause = Clause.or([
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "wrong_value")),
            .token(Clause.TokenClause(token: "active", operator: .equals, value: "active"))
        ])
        
        XCTAssertTrue(orClause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(orClause.description, "premium equals wrong_value OR active equals active")
    }

    func testOrClauseWithAllFalseConditions() {
        let orClause = Clause.or([
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "wrong_value1")),
            .token(Clause.TokenClause(token: "active", operator: .equals, value: "wrong_value2"))
        ])
        
        XCTAssertFalse(orClause.evaluate(state: ConditionalState(formState: [:])))
    }
    
    func testSingleOr() {
        let orClause = Clause.or([
            .token(Clause.TokenClause(token: "active", operator: .equals, value: "active"))
        ])
        
        XCTAssertTrue(orClause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(orClause.description, "active equals active")
    }

    func testEmptyOrClause() {
        let orClause = Clause.or([])
        let state = ConditionalState(formState: [:])

        // Empty OR clause should evaluate to false (no conditions are satisfied)
        XCTAssertFalse(orClause.evaluate(state: state))
        XCTAssertEqual(orClause.description, "")
    }

    // MARK: - Not Clause

    func testNotClause() {
        let notClause = Clause.not(
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "wrong_value"))
        )
        
        XCTAssertTrue(notClause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(notClause.description, "NOT premium equals wrong_value")
    }

    func testNotClauseWithTrueCondition() {
        let notClause = Clause.not(
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "premium"))
        )
        
        XCTAssertFalse(notClause.evaluate(state: ConditionalState(formState: [:])))
    }

    func testNestedNotClause() {
        let tokenClause = Clause.TokenClause(token: "premium", operator: .equals, value: "premium")
        let notClause = Clause.not(.token(tokenClause))
        let doubleNotClause = Clause.not(notClause)

        XCTAssertTrue(doubleNotClause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(doubleNotClause.description, "NOT NOT premium equals premium")
    }

    // MARK: - Survey Clause

    func testSurveyClause() {
        let block = UUID()
        let state = ConditionalState(formState: [block: "test_value"])

        let clause = Clause.survey(Clause.SurveyClause(block: block, operator: .equals, value: "test_value"))
        
        XCTAssertTrue(clause.evaluate(state: state))
        XCTAssertEqual(clause.description, "\(block) equals test_value")
    }

    func testSurveyClauseWithMissingBlock() {
        let block = UUID()
        let state = ConditionalState(formState: [:])

        let surveyClause = Clause.SurveyClause(block: block, operator: .equals, value: "test_value")
        let clause = Clause.survey(surveyClause)
        
        XCTAssertFalse(clause.evaluate(state: state))
    }

    // MARK: - Token Clause

    func testTokenClause() {
        let tokenClause = Clause.TokenClause(token: "test_token", operator: .equals, value: "test_token")
        let clause = Clause.token(tokenClause)
        
        XCTAssertTrue(clause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(clause.description, "test_token equals test_token")
    }

    func testTokenClauseWithDifferentValues() {
        let tokenClause = Clause.TokenClause(token: "test_token", operator: .equals, value: "different_value")
        let clause = Clause.token(tokenClause)

        XCTAssertFalse(clause.evaluate(state: ConditionalState(formState: [:])))
        XCTAssertEqual(clause.description, "test_token equals different_value")
    }

    // MARK: - Unknown Clause

    func testUnknownClause() {
        let clause = Clause.unknown
        let state = ConditionalState(formState: [:])

        XCTAssertFalse(clause.evaluate(state: state))
        XCTAssertEqual(clause.description, "unknown clause")
    }

    // MARK: - Operator Tests

    func testEqualsOperator() {
        let op = Clause.Operator.equals
        XCTAssertTrue(op.evaluate("test", "test"))
        XCTAssertFalse(op.evaluate("test", "other"))
        XCTAssertEqual(op.description, "equals")
    }

    func testCaseSensitiveOperators() {
        let op = Clause.Operator.equals
        XCTAssertFalse(op.evaluate("Hello", "hello"))
        XCTAssertTrue(op.evaluate("Hello", "Hello"))
    }

    func testWhitespaceHandling() {
        let op = Clause.Operator.equals
        XCTAssertFalse(op.evaluate("hello", " hello "))
        XCTAssertTrue(op.evaluate(" hello ", " hello "))
    }

    func testDoesntEqualOperator() {
        let op = Clause.Operator.doesntEqual
        XCTAssertTrue(op.evaluate("test", "other"))
        XCTAssertFalse(op.evaluate("test", "test"))
        XCTAssertEqual(op.description, "doesn't equal")
    }

    func testContainsOperator() {
        let op = Clause.Operator.contains
        XCTAssertTrue(op.evaluate("hello world", "world"))
        XCTAssertTrue(op.evaluate("hello world", "hello"))
        XCTAssertTrue(op.evaluate("hello world", "ll"))
        XCTAssertFalse(op.evaluate("hello world", "xyz"))
        XCTAssertEqual(op.description, "contains")
    }

    func testDoesntContainOperator() {
        let op = Clause.Operator.doesntContain
        XCTAssertTrue(op.evaluate("hello world", "xyz"))
        XCTAssertFalse(op.evaluate("hello world", "world"))
        XCTAssertFalse(op.evaluate("hello world", "hello"))
        XCTAssertEqual(op.description, "doesn't contain")
    }

    func testStartsWithOperator() {
        let op = Clause.Operator.startsWith
        XCTAssertTrue(op.evaluate("hello world", "hello"))
        XCTAssertFalse(op.evaluate("hello world", "world"))
        XCTAssertFalse(op.evaluate("hello world", "xyz"))
        XCTAssertEqual(op.description, "starts with")
    }

    func testDoesntStartWithOperator() {
        let op = Clause.Operator.doesntStartWith
        XCTAssertTrue(op.evaluate("hello world", "world"))
        XCTAssertTrue(op.evaluate("hello world", "xyz"))
        XCTAssertFalse(op.evaluate("hello world", "hello"))
        XCTAssertEqual(op.description, "doesn't start with")
    }

    func testEndsWithOperator() {
        let op = Clause.Operator.endsWith
        XCTAssertTrue(op.evaluate("hello world", "world"))
        XCTAssertFalse(op.evaluate("hello world", "hello"))
        XCTAssertFalse(op.evaluate("hello world", "xyz"))
        XCTAssertEqual(op.description, "ends with")
    }

    func testDoesntEndWithOperator() {
        let op = Clause.Operator.doesntEndWith
        XCTAssertTrue(op.evaluate("hello world", "hello"))
        XCTAssertTrue(op.evaluate("hello world", "xyz"))
        XCTAssertFalse(op.evaluate("hello world", "world"))
        XCTAssertEqual(op.description, "doesn't end with")
    }

    func testMatchesRegexOperator() {
        let op = Clause.Operator.matchesRegex
        XCTAssertTrue(op.evaluate("hello123world", "\\d+"))
        XCTAssertFalse(op.evaluate("hello world", "\\d+"))
        XCTAssertEqual(op.description, "matches regex")
    }

    func testMatchesRegexOperatorWithInvalidPattern() {
        let op = Clause.Operator.matchesRegex
        XCTAssertFalse(op.evaluate("test", "[")) // Invalid regex pattern
        XCTAssertFalse(op.evaluate("test", "")) // Empty regex pattern
    }

    func testIsOneOfOperator() {
        let op = Clause.Operator.isOneOf
        XCTAssertTrue(op.evaluate("option1\noption2\noption3", "option2"))
        XCTAssertTrue(op.evaluate("option1\noption2\noption3", "option1"))
        XCTAssertFalse(op.evaluate("option1\noption2\noption3", "option4"))
        XCTAssertEqual(op.description, "is one of")
    }

    func testIsntOneOfOperator() {
        let op = Clause.Operator.isntOneOf
        XCTAssertTrue(op.evaluate("option1\noption2\noption3", "option4"))
        XCTAssertFalse(op.evaluate("option1\noption2\noption3", "option2"))
        XCTAssertFalse(op.evaluate("option1\noption2\noption3", "option1"))
        XCTAssertEqual(op.description, "isn't one of")
    }

    func testNumericOperators() {
        // Greater than
        XCTAssertTrue(Clause.Operator.isGreaterThan.evaluate("10", "5"))
        XCTAssertFalse(Clause.Operator.isGreaterThan.evaluate("5", "5"))
        XCTAssertFalse(Clause.Operator.isGreaterThan.evaluate("5", "10"))
        XCTAssertEqual(Clause.Operator.isGreaterThan.description, "is greater than")

        // Greater or equal
        XCTAssertTrue(Clause.Operator.isGreaterOrEqual.evaluate("10", "5"))
        XCTAssertTrue(Clause.Operator.isGreaterOrEqual.evaluate("5", "5"))
        XCTAssertFalse(Clause.Operator.isGreaterOrEqual.evaluate("5", "10"))
        XCTAssertEqual(Clause.Operator.isGreaterOrEqual.description, "is greater than or equal to")

        // Less than
        XCTAssertTrue(Clause.Operator.islessThan.evaluate("5", "10"))
        XCTAssertFalse(Clause.Operator.islessThan.evaluate("5", "5"))
        XCTAssertFalse(Clause.Operator.islessThan.evaluate("10", "5"))
        XCTAssertEqual(Clause.Operator.islessThan.description, "is less than")

        // Less or equal
        XCTAssertTrue(Clause.Operator.isLessOrEqual.evaluate("5", "10"))
        XCTAssertTrue(Clause.Operator.isLessOrEqual.evaluate("5", "5"))
        XCTAssertFalse(Clause.Operator.isLessOrEqual.evaluate("10", "5"))
        XCTAssertEqual(Clause.Operator.isLessOrEqual.description, "is less than or equal to")
    }

    func testDecimalNumericOperators() {
        // Greater than
        XCTAssertTrue(Clause.Operator.isGreaterThan.evaluate("10.25", "10.10"))
        XCTAssertFalse(Clause.Operator.isGreaterThan.evaluate("10.10", "10.10"))
        XCTAssertFalse(Clause.Operator.isGreaterThan.evaluate("10.10", "10.25"))

        // Greater or equal
        XCTAssertTrue(Clause.Operator.isGreaterOrEqual.evaluate("10.25", "10.10"))
        XCTAssertTrue(Clause.Operator.isGreaterOrEqual.evaluate("10.10", "10.10"))
        XCTAssertFalse(Clause.Operator.isGreaterOrEqual.evaluate("10.10", "10.25"))

        // Less than
        XCTAssertTrue(Clause.Operator.islessThan.evaluate("10.10", "10.25"))
        XCTAssertFalse(Clause.Operator.islessThan.evaluate("10.10", "10.10"))
        XCTAssertFalse(Clause.Operator.islessThan.evaluate("10.25", "10.10"))

        // Less or equal
        XCTAssertTrue(Clause.Operator.isLessOrEqual.evaluate("10.10", "10.25"))
        XCTAssertTrue(Clause.Operator.isLessOrEqual.evaluate("10.10", "10.10"))
        XCTAssertFalse(Clause.Operator.isLessOrEqual.evaluate("10.25", "10.10"))
    }

    func testNegativeNumericOperators() {
        // Greater than
        XCTAssertTrue(Clause.Operator.isGreaterThan.evaluate("-5", "-10"))
        XCTAssertFalse(Clause.Operator.isGreaterThan.evaluate("-5", "-5"))
        XCTAssertFalse(Clause.Operator.isGreaterThan.evaluate("-10", "-5"))

        // Greater or equal
        XCTAssertTrue(Clause.Operator.isGreaterOrEqual.evaluate("-5", "-10"))
        XCTAssertTrue(Clause.Operator.isGreaterOrEqual.evaluate("-5", "-5"))
        XCTAssertFalse(Clause.Operator.isGreaterOrEqual.evaluate("-10", "-5"))

        // Less than
        XCTAssertTrue(Clause.Operator.islessThan.evaluate("-10", "-5"))
        XCTAssertFalse(Clause.Operator.islessThan.evaluate("-5", "-5"))
        XCTAssertFalse(Clause.Operator.islessThan.evaluate("-5", "-10"))

        // Less or equal
        XCTAssertTrue(Clause.Operator.isLessOrEqual.evaluate("-10", "-5"))
        XCTAssertTrue(Clause.Operator.isLessOrEqual.evaluate("-5", "-5"))
        XCTAssertFalse(Clause.Operator.isLessOrEqual.evaluate("-5", "-10"))
    }

    func testNumericOperatorsWithNonNumericStrings() {
        // Non-numeric values always result in an evaluation of false
        XCTAssertFalse(Clause.Operator.isGreaterThan.evaluate("5", "a"))
        XCTAssertFalse(Clause.Operator.isGreaterOrEqual.evaluate("5", "a"))
        XCTAssertFalse(Clause.Operator.islessThan.evaluate("5", "a"))
        XCTAssertFalse(Clause.Operator.isLessOrEqual.evaluate("5", "a"))
    }

    func testOperatorRawValues() {
        XCTAssertEqual(Clause.Operator.equals.rawValue, "==")
        XCTAssertEqual(Clause.Operator.doesntEqual.rawValue, "!=")
        XCTAssertEqual(Clause.Operator.contains.rawValue, "*")
        XCTAssertEqual(Clause.Operator.doesntContain.rawValue, "!*")
        XCTAssertEqual(Clause.Operator.startsWith.rawValue, "^")
        XCTAssertEqual(Clause.Operator.doesntStartWith.rawValue, "!^")
        XCTAssertEqual(Clause.Operator.endsWith.rawValue, "$")
        XCTAssertEqual(Clause.Operator.doesntEndWith.rawValue, "!$")
        XCTAssertEqual(Clause.Operator.matchesRegex.rawValue, "regex")
        XCTAssertEqual(Clause.Operator.isOneOf.rawValue, "in")
        XCTAssertEqual(Clause.Operator.isntOneOf.rawValue, "not in")
        XCTAssertEqual(Clause.Operator.isGreaterThan.rawValue, ">")
        XCTAssertEqual(Clause.Operator.isGreaterOrEqual.rawValue, ">=")
        XCTAssertEqual(Clause.Operator.islessThan.rawValue, "<")
        XCTAssertEqual(Clause.Operator.isLessOrEqual.rawValue, "<=")
    }

    // MARK: - JSON Decoding Tests

    func testDecodeAndClause() throws {
        let json = """
        {
            "and": [
                {
                    "token": {
                        "token": "user_type",
                        "operator": "==",
                        "value": "premium"
                    }
                },
                {
                    "survey": {
                        "block": "123e4567-e89b-12d3-a456-426614174000",
                        "operator": "*",
                        "value": "contains"
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        switch clause {
        case .and(let conditions):
            XCTAssertEqual(conditions.count, 2)
            
            if case .token(let tokenClause) = conditions[0] {
                XCTAssertEqual(tokenClause.token, "user_type")
                XCTAssertEqual(tokenClause.operator, .equals)
                XCTAssertEqual(tokenClause.value, "premium")
            } else {
                XCTFail("Expected token clause")
            }
            
            if case .survey(let surveyClause) = conditions[1] {
                XCTAssertEqual(surveyClause.block.appcuesFormatted, "123e4567-e89b-12d3-a456-426614174000")
                XCTAssertEqual(surveyClause.operator, .contains)
                XCTAssertEqual(surveyClause.value, "contains")
            } else {
                XCTFail("Expected survey clause")
            }
        default:
            XCTFail("Expected and clause")
        }
    }

    func testDecodeOrClause() throws {
        let json = """
        {
            "or": [
                {
                    "survey": {
                        "block": "123e4567-e89b-12d3-a456-426614174000",
                        "operator": "!=",
                        "value": "wrong_value"
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        switch clause {
        case .or(let conditions):
            XCTAssertEqual(conditions.count, 1)
            
            if case .survey(let surveyClause) = conditions[0] {
                XCTAssertEqual(surveyClause.block.appcuesFormatted, "123e4567-e89b-12d3-a456-426614174000")
                XCTAssertEqual(surveyClause.operator, .doesntEqual)
                XCTAssertEqual(surveyClause.value, "wrong_value")
            } else {
                XCTFail("Expected survey clause")
            }
        default:
            XCTFail("Expected or clause")
        }
    }

    func testDecodeNotClause() throws {
        let json = """
        {
            "not": {
                "survey": {
                    "block": "123e4567-e89b-12d3-a456-426614174000",
                    "operator": "^",
                    "value": "prefix"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        switch clause {
        case .not(let innerClause):
            if case .survey(let surveyClause) = innerClause {
                XCTAssertEqual(surveyClause.block.appcuesFormatted, "123e4567-e89b-12d3-a456-426614174000")
                XCTAssertEqual(surveyClause.operator, .startsWith)
                XCTAssertEqual(surveyClause.value, "prefix")
            } else {
                XCTFail("Expected survey clause")
            }
        default:
            XCTFail("Expected not clause")
        }
    }

    func testDecodeSurveyClause() throws {
        let json = """
        {
            "survey": {
                "block": "123e4567-e89b-12d3-a456-426614174000",
                "operator": "$",
                "value": "suffix"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        switch clause {
        case .survey(let surveyClause):
            XCTAssertEqual(surveyClause.block.appcuesFormatted, "123e4567-e89b-12d3-a456-426614174000")
            XCTAssertEqual(surveyClause.operator, .endsWith)
            XCTAssertEqual(surveyClause.value, "suffix")
        default:
            XCTFail("Expected survey clause")
        }
    }

    func testDecodeTokenClause() throws {
        let json = """
        {
            "token": {
                "token": "user_type",
                "operator": "in",
                "value": "premium\\nvip\\nadmin"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        switch clause {
        case .token(let tokenClause):
            XCTAssertEqual(tokenClause.token, "user_type")
            XCTAssertEqual(tokenClause.operator, .isOneOf)
            XCTAssertEqual(tokenClause.value, "premium\nvip\nadmin")
        default:
            XCTFail("Expected token clause")
        }
    }

    func testDecodeComplexNestedClause() throws {
        let json = """
        {
            "and": [
                { "or": [
                    { "token": { "token": "user_type", "operator": "==", "value": "premium" }},
                    { "survey": { "block": "123e4567-e89b-12d3-a456-426614174000", "operator": ">", "value": "5" }}
                ]},
                { "not": { "token": { "token": "user_status", "operator": "==", "value": "blocked" }}}
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        guard case .and(let andClauses) = clause else {
            XCTFail("Expected and clause")
            return
        }
        XCTAssertEqual(andClauses.count, 2)

        guard case .or(let orClauses) = andClauses[safe: 0] else {
            XCTFail("Expected or clause")
            return
        }
        XCTAssertEqual(orClauses.count, 2)

        guard case .token(let firstTokenClause) = orClauses[safe: 0] else {
            XCTFail("Expected token clause")
            return
        }
        XCTAssertEqual(firstTokenClause.token, "user_type")
        XCTAssertEqual(firstTokenClause.operator, .equals)
        XCTAssertEqual(firstTokenClause.value, "premium")

        guard case .survey(let surveyClause) = orClauses[safe: 1] else {
            XCTFail("Expected survey clause")
            return
        }
        XCTAssertEqual(surveyClause.operator, .isGreaterThan)
        XCTAssertEqual(surveyClause.value, "5")

        guard case .not(let notClause) = andClauses[safe: 1] else {
            XCTFail("Expected not clause")
            return
        }

        guard case .token(let secondTokenClause) = notClause else {
            XCTFail("Expected token clause")
            return
        }
        XCTAssertEqual(secondTokenClause.token, "user_status")
        XCTAssertEqual(secondTokenClause.operator, .equals)
        XCTAssertEqual(secondTokenClause.value, "blocked")
        XCTAssertEqual(clause.description, "user_type equals premium OR 123E4567-E89B-12D3-A456-426614174000 is greater than 5 AND NOT user_status equals blocked")
    }

    func testDecodeUnknownClause() throws {
        let json = """
        {
            "unknown_key": "some_value"
        }
        """

        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        switch clause {
        case .unknown:
            // This is expected behavior - unknown clauses should decode to .unknown
            break
        default:
            XCTFail("Expected unknown clause")
        }
    }

    func testDecodeEmptyObject() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let clause = try JSONDecoder().decode(Clause.self, from: data)

        switch clause {
        case .unknown:
            // This is expected behavior - empty objects should decode to .unknown
            break
        default:
            XCTFail("Expected unknown clause")
        }
    }

    func testDecodeMultipleKeysError() throws {
        let json = """
        {
            "and": [],
            "or": []
        }
        """

        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Clause.self, from: data))
    }

    func testDecodeInvalidUUID() throws {
        let json = """
        {
            "survey": {
                "block": "invalid-uuid",
                "operator": "==",
                "value": "test"
            }
        }
        """

        let data = json.data(using: .utf8)!

        // This should throw a decoding error due to invalid UUID
        XCTAssertThrowsError(try JSONDecoder().decode(Clause.self, from: data))
    }

    func testDecodeInvalidOperator() throws {
        let json = """
        {
            "survey": {
                "block": "123e4567-e89b-12d3-a456-426614174000",
                "operator": "invalid_operator",
                "value": "test"
            }
        }
        """

        let data = json.data(using: .utf8)!

        // This should throw a decoding error due to invalid operator
        XCTAssertThrowsError(try JSONDecoder().decode(Clause.self, from: data))
    }

    func testDecodeUnknownOperator() throws {
        let json = """
        {
            "token": {
                "token": "test",
                "operator": "unknown",
                "value": "test"
            }
        }
        """

        let data = json.data(using: .utf8)!

        // This should throw a decoding error due to unknown operator
        XCTAssertThrowsError(try JSONDecoder().decode(Clause.self, from: data))
    }

    // MARK: - Integration Tests

    func testComplexClauseEvaluation() {
        let tokenClause1 = Clause.TokenClause(token: "user_type", operator: .equals, value: "premium")
        let tokenClause2 = Clause.TokenClause(token: "user_status", operator: .equals, value: "active")
        let tokenClause3 = Clause.TokenClause(token: "user_role", operator: .doesntEqual, value: "admin")

        let orClause = Clause.or([.token(tokenClause1), .token(tokenClause2)])
        let notClause = Clause.not(.token(tokenClause3))
        let andClause = Clause.and([orClause, notClause])

        // (user_type == "premium" OR user_status == "active") AND NOT (user_role != "admin")
        // (true OR true) AND NOT (true) = true AND false = false
        XCTAssertFalse(andClause.evaluate(state: ConditionalState(formState: [:])))
    }

    func testMixedClauseTypes() {
        let block = UUID()
        let state = ConditionalState(formState: [block: "yes"])

        let surveyClause = Clause.SurveyClause(block: block, operator: .equals, value: "yes")
        let tokenClause = Clause.TokenClause(token: "premium", operator: .equals, value: "premium")

        let andClause = Clause.and([.survey(surveyClause), .token(tokenClause)])
        
        XCTAssertTrue(andClause.evaluate(state: state))
        XCTAssertEqual(andClause.description, "\(block) equals yes AND premium equals premium")
    }

    func testMixedClauseTypesWithFalseCondition() {
        let block = UUID()
        let state = ConditionalState(formState: [block: "no"])

        let orClause = Clause.or([
            .survey(Clause.SurveyClause(block: block, operator: .equals, value: "yes")),
            .token(Clause.TokenClause(token: "premium", operator: .equals, value: "premium"))
        ])

        // Survey condition is false, but token condition is true, so OR should be true
        XCTAssertTrue(orClause.evaluate(state: state))
        XCTAssertEqual(orClause.description, "\(block) equals yes OR premium equals premium")
    }
}
