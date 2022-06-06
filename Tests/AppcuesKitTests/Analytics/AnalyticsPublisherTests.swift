//
//  AnalyticsPublisherTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-05-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AnalyticsPublisherTests: XCTestCase {

    var analyticsPublisher: AnalyticsPublisher!
    var appcues: MockAppcues!

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00001", applicationID: "abc")
            .anonymousIDFactory({ "my-anonymous-id" })

        appcues = MockAppcues(config: config)
        appcues.sessionID = UUID()
        analyticsPublisher = AnalyticsPublisher(container: appcues.container)
    }
    func testRegisterDecorator() throws {
        // Arrange
        let decorator = Mocks.TestDecorator()

        // Act
        analyticsPublisher.register(decorator: decorator)
        analyticsPublisher.publish(TrackingUpdate(type: .event(name: "custom event", interactive: true)))

        // Assert
        XCTAssertEqual(1, decorator.decorations)
    }

    func testRemoveDecorator() throws {
        // Arrange
        let decorator = Mocks.TestDecorator()
        analyticsPublisher.register(decorator: decorator)
        analyticsPublisher.publish(TrackingUpdate(type: .event(name: "custom event", interactive: true)))

        // Act
        analyticsPublisher.remove(decorator: decorator)
        analyticsPublisher.publish(TrackingUpdate(type: .event(name: "custom event", interactive: true)))

        // Assert
        XCTAssertEqual(1, decorator.decorations)
    }

    func testWeakDecorator() throws {
        // Arrange
        var decorator: Mocks.TestDecorator? = Mocks.TestDecorator()
        weak var weakDecorator: Mocks.TestDecorator? = decorator
        analyticsPublisher.register(decorator: decorator!)

        // Act
        decorator = nil

        // Assert
        XCTAssertNil(weakDecorator)
    }

    func testRegisterSubscriber() throws {
        // Arrange
        let subscriber = Mocks.TestSubscriber()

        // Act
        analyticsPublisher.register(subscriber: subscriber)
        analyticsPublisher.publish(TrackingUpdate(type: .event(name: "custom event", interactive: true)))

        // Assert
        XCTAssertEqual(1, subscriber.trackedUpdates)
    }

    func testRemoveSubscriber() throws {
        // Arrange
        let subscriber = Mocks.TestSubscriber()
        analyticsPublisher.register(subscriber: subscriber)
        analyticsPublisher.publish(TrackingUpdate(type: .event(name: "custom event", interactive: true)))

        // Act
        analyticsPublisher.remove(subscriber: subscriber)
        analyticsPublisher.publish(TrackingUpdate(type: .event(name: "custom event", interactive: true)))

        // Assert
        XCTAssertEqual(1, subscriber.trackedUpdates)
    }

    func testWeakSubscriber() throws {
        // Arrange
        var subscriber: Mocks.TestSubscriber? = Mocks.TestSubscriber()
        weak var weakSubscriber: Mocks.TestSubscriber? = subscriber
        analyticsPublisher.register(subscriber: subscriber!)

        // Act
        subscriber = nil

        // Assert
        XCTAssertNil(weakSubscriber)
    }

}
