//
//  AppcuesTests.swift
//  AppcuesTests
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class AppcuesTests: XCTestCase {
    var appcues: MockAppcues!

    override func setUpWithError() throws {
        let config = Appcues.Config(accountID: "00001", applicationID: "abc")
            .anonymousIDFactory({ "my-anonymous-id" })

        appcues = MockAppcues(config: config)
    }

    func testAnonymousTracking() throws {
        // Test to validate that (1) no activity flows through system when no user has been identified (anon or auth)
        // and (2) validate that activity does begin flowing through once the user is known (anon or auth)

        // Arrange
        // Need to use a real AnalyticsPublisher, not the mock because the real one filters on the session state
        let realPublisher = AnalyticsPublisher(container: appcues.container)
        appcues.container.register(AnalyticsPublishing.self, value: realPublisher)
        let subscriber = Mocks.TestSubscriber()
        realPublisher.register(subscriber: subscriber)
        
        appcues.sessionID = nil //start out with Appcues disabled - no user
        appcues.storage.userID = ""

        appcues.sessionMonitor.onStart = {
            guard !self.appcues.storage.userID.isEmpty else { return false }
            self.appcues.sessionID = UUID()
            return true
        }

        appcues.sessionMonitor.onReset = {
            self.appcues.sessionID = nil
        }

        // Act
        appcues.screen(title: "My test page") // not tracked
        appcues.anonymous()                   // tracked 2 - session start + user
        appcues.screen(title: "My test page") // tracked 1 - screen
        appcues.reset()                       // tracked 1 - device unregister and stop tracking
        appcues.screen(title: "My test page") // not tracked
        appcues.identify(userID: "a-user-id") // tracked 2 - session start + user
        appcues.screen(title: "My test page") // tracked 1 - screen

        // Assert
        XCTAssertEqual(7, subscriber.trackedUpdates)
    }

    func testAnonymousUserIdPrefix() throws {
        // Act
        appcues.anonymous()

        // Assert
        XCTAssertEqual("anon:", appcues.storage.userID.prefix(5))
    }

    func testIdentifyWithEmptyUserIsNotTracked() throws {
        // Arrange
        var trackedUpdates = 0
        appcues.analyticsPublisher.onPublish = { _ in trackedUpdates += 1 }

        // Act
        appcues.identify(userID: "", properties: nil)

        // Assert
        XCTAssertEqual(0, trackedUpdates)
    }

    func testIdentifyWithUserSignature() throws {
        // Act
        appcues.identify(userID: "test-user", properties: ["appcues:user_id_signature": "user-signature"])

        // Assert
        XCTAssertEqual("user-signature", appcues.storage.userSignature)
    }

    func testIdentifyWithoutUserSignature() throws {
        // Act
        appcues.identify(userID: "test-user", properties: ["foo": 100])

        // Assert
        XCTAssertNil(appcues.storage.userSignature)
    }

    func testIdentifyTriggersDeferredPush() throws {
        // Arrange
        var deferredPushAttempts = 0
        appcues.pushMonitor.onAttemptDeferredNotificationResponse = { deferredPushAttempts += 1 }

        // Act
        appcues.identify(userID: "test-user")

        // Assert
        XCTAssertEqual(deferredPushAttempts, 1)
    }

    func testIdentifySameUserTriggersDeviceUpdate() throws {
        // Arrange
        let deviceUpdateExpectation = expectation(description: "Device updated")
        appcues.analyticsPublisher.onPublish = { update in
            if case .event("appcues:device_updated", true) = update.type {
                deviceUpdateExpectation.fulfill()
            }
        }
        appcues.storage.userID = "test-user"

        // Act
        appcues.identify(userID: "test-user") // re-identify

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testIdentifyNewUserDoesNotTriggerDeviceUpdate() throws {
        // no device update here since the new user will trigger a new session_started
        // event with device props

        // Arrange
        let deviceUpdateExpectation = expectation(description: "Device updated")
        deviceUpdateExpectation.isInverted = true
        appcues.analyticsPublisher.onPublish = { update in
            if case .event("appcues:device_updated", true) = update.type {
                deviceUpdateExpectation.fulfill()
            }
        }
        appcues.storage.userID = "test-user"

        // Act
        appcues.identify(userID: "different-user")

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testReset() throws {
        // Act
        appcues.identify(userID: "test-user", properties: ["foo": 100])
        appcues.group(groupID: "test-group")
        appcues.reset()

        // Assert
        XCTAssertEqual("", appcues.storage.userID)
        XCTAssertNil(appcues.storage.groupID)
        XCTAssertNil(appcues.storage.userSignature)
    }

    func testSetGroup() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

        // Act
        appcues.group(groupID: "group1", properties: ["my_key":"my_value", "another_key": 33])

        // Assert
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .group = lastUpdate.type else { return XCTFail() }
        ["my_key":"my_value", "another_key": 33].verifyPropertiesMatch(lastUpdate.properties)
        XCTAssertEqual("group1", appcues.storage.groupID)
    }

    func testNilGroupIDRemovesGroup() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

        // Act
        appcues.group(groupID: nil, properties: ["my_key":"my_value", "another_key": 33])

        // Assert
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .group = lastUpdate.type else { return XCTFail() }
        XCTAssertNil(appcues.storage.groupID)
        XCTAssertNil(lastUpdate.properties)
    }

    func testEmptyStringGroupIDRemovesGroup() throws {
        // Arrange
        var mostRecentUpdate: TrackingUpdate?
        appcues.analyticsPublisher.onPublish = { update in mostRecentUpdate = update }

        // Act
        appcues.group(groupID: "", properties: ["my_key":"my_value", "another_key": 33])

        // Assert
        let lastUpdate = try XCTUnwrap(mostRecentUpdate)
        guard case .group = lastUpdate.type else { return XCTFail() }
        XCTAssertNil(appcues.storage.groupID)
        XCTAssertNil(lastUpdate.properties)
    }

    func testSdkVersion() throws {
        // Act
        let version = appcues.version()
        let tokens = version.split(separator: ".")

        // Assert
        // just looking for some valid return string with at least a major/minor version
        XCTAssertTrue(tokens.count > 2)
        XCTAssertNotNil(Int(tokens[0]))
        XCTAssertNotNil(Int(tokens[1]))
    }

    func testDebug() throws {
        // Arrange
        let debuggerShownExpectation = expectation(description: "Debugger shown")
        appcues.debugger.onShow = { mode in
            guard case let .debugger(destination) = mode else { return XCTFail() }
            XCTAssertNil(destination)
            debuggerShownExpectation.fulfill()
        }

        // Act
        appcues.debug()

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testShowExperienceByID() throws {
        // Arrange
        appcues.sessionID = UUID()
        var completionCount = 0
        var experienceShownCount = 0
        appcues.contentLoader.onLoad = { experienceID, published, trigger, completion in
            XCTAssertEqual(true, published)
            XCTAssertEqual("1234", experienceID)
            guard case .showCall = trigger else { return XCTFail() }
            experienceShownCount += 1
            completion?(.success(()))
        }

        // Act
        appcues.show(experienceID: "1234") { success, _ in
            if success {
                completionCount += 1
            }
        }

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(experienceShownCount, 1)
    }

    func testExperienceNotShownIfNoSession() throws {
        // Arrange
        appcues.sessionID = nil
        var completionCount = 0
        var experienceShownCount = 0
        appcues.contentLoader.onLoad = { experienceID, published, trigger, completion in
            experienceShownCount += 1
            completion?(.failure(AppcuesError.noActiveSession))
        }

        // Act
        appcues.show(experienceID: "1234") { success, _ in
            if !success {
                completionCount += 1
            }
        }

        // Assert
        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(experienceShownCount, 0)
    }

    func testAutomaticScreenTracking() throws {
        // Arrange
        let screenExpectation = expectation(description: "Screen tracked")
        appcues.analyticsPublisher.onPublish = { trackingUpdate in
            XCTAssertEqual(trackingUpdate.type, .screen("test screen"))
            XCTAssertNil(trackingUpdate.properties)
            screenExpectation.fulfill()
        }

        // Act
        appcues.trackScreens()
        // simulates an automatic tracked screen to verify if tracking is handling
        NotificationCenter.appcues.post(name: .appcuesTrackedScreen,
                                        object: self,
                                        userInfo: Notification.toInfo("test screen"))

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testSetPushToken() throws {
        // Arrange
        let token = "some-token".data(using: .utf8)

        let setExpectation = expectation(description: "Token set")
        appcues.pushMonitor.onSetPushToken = {
            XCTAssertEqual($0, token)
            setExpectation.fulfill()
        }

        // Act
        appcues.setPushToken(token)

        // Assert
        waitForExpectations(timeout: 1)
    }

    func testDidHandleURL() throws {
        // Arrange
        appcues.deepLinkHandler.onDidHandleURL = { url -> Bool in
            XCTAssertEqual(URL(string: "https://www.appcues.com")!, url)
            return true
        }

        // Act
        let result = appcues.didHandleURL(URL(string: "https://www.appcues.com")!)

        // Assert
        XCTAssertTrue(result)
    }

    // Test that all the components are properly deinited when the Appcues instance is
    func testDeinit() throws {
        // Arrange
        var appcues: Appcues? = Appcues(config: Appcues.Config(accountID: "abc", applicationID: "123"))

        weak var weakAppcues = appcues
        weak var weakConfig = appcues?.container.resolve(Appcues.Config.self)
        weak var weakAnalyticsPublishing = appcues?.container.resolve(AnalyticsPublishing.self)
        weak var weakDataStoring = appcues?.container.resolve(DataStoring.self)
        weak var weakNetworking = appcues?.container.resolve(Networking.self)
        weak var weakAnalyticsTracking = appcues?.container.resolve(AnalyticsTracking.self)
        weak var weakSessionMonitoring = appcues?.container.resolve(SessionMonitoring.self)
        weak var weakUIKitScreenTracker = appcues?.container.resolve(UIKitScreenTracker.self)
        weak var weakAutoPropertyDecoration = appcues?.container.resolve(AutoPropertyDecorator.self)
        weak var weakActivityProcessing = appcues?.container.resolve(ActivityProcessing.self)
        weak var weakActivityStoring = appcues?.container.resolve(ActivityStoring.self)
        weak var weakDeepLinkHandling = appcues?.container.resolve(DeepLinkHandling.self)
        weak var weakUIDebugging = appcues?.container.resolve(UIDebugging.self)
        weak var weakContentLoading = appcues?.container.resolve(ContentLoading.self)
        weak var weakExperienceRendering = appcues?.container.resolve(ExperienceRendering.self)
        weak var weakTraitRegistry = appcues?.container.resolve(TraitRegistry.self)
        weak var weakActionRegistry = appcues?.container.resolve(ActionRegistry.self)
        weak var weakTraitComposing = appcues?.container.resolve(TraitComposing.self)

        XCTAssertNotNil(weakAppcues)
        XCTAssertNotNil(weakConfig)
        XCTAssertNotNil(weakAnalyticsPublishing)
        XCTAssertNotNil(weakDataStoring)
        XCTAssertNotNil(weakNetworking)
        XCTAssertNotNil(weakAnalyticsTracking)
        XCTAssertNotNil(weakSessionMonitoring)
        XCTAssertNotNil(weakUIKitScreenTracker)
        XCTAssertNotNil(weakAutoPropertyDecoration)
        XCTAssertNotNil(weakActivityProcessing)
        XCTAssertNotNil(weakActivityStoring)
        XCTAssertNotNil(weakDeepLinkHandling)
        XCTAssertNotNil(weakUIDebugging)
        XCTAssertNotNil(weakContentLoading)
        XCTAssertNotNil(weakExperienceRendering)
        XCTAssertNotNil(weakTraitRegistry)
        XCTAssertNotNil(weakActionRegistry)
        XCTAssertNotNil(weakTraitComposing)

        // Act
        appcues = nil

        // Assert
        XCTAssertNil(weakAppcues)
        XCTAssertNil(weakConfig)
        XCTAssertNil(weakAnalyticsPublishing)
        XCTAssertNil(weakDataStoring)
        XCTAssertNil(weakNetworking)
        XCTAssertNil(weakAnalyticsTracking)
        XCTAssertNil(weakSessionMonitoring)
        XCTAssertNil(weakUIKitScreenTracker)
        XCTAssertNil(weakAutoPropertyDecoration)
        XCTAssertNil(weakActivityProcessing)
        XCTAssertNil(weakActivityStoring)
        XCTAssertNil(weakDeepLinkHandling)
        XCTAssertNil(weakUIDebugging)
        XCTAssertNil(weakContentLoading)
        XCTAssertNil(weakExperienceRendering)
        XCTAssertNil(weakTraitRegistry)
        XCTAssertNil(weakActionRegistry)
        XCTAssertNil(weakTraitComposing)
    }

    func testDIContainerThreadSafety() throws {
        // Arrange
        let dispatchGroup = DispatchGroup()
        let completeExpectation = expectation(description: "multi thread")
        completeExpectation.expectedFulfillmentCount = 100

        let container = DIContainer()

        // Act
        // Register and read a dependency on 100 threads
        for i in 0..<100 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let dep = Appcues.Config(accountID: "<acc_id>", applicationID: "<app_id>")
                container.register(Appcues.Config.self, value: dep)
                _ = container.resolve(Appcues.Config.self)
                completeExpectation.fulfill()
                print("Resolved", i)
                dispatchGroup.leave()
            }
        }

        // Assert
        waitForExpectations(timeout: 2)

    }
}
