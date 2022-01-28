//
//  MockAppcues.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 1/7/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
@testable import AppcuesKit

class MockAppcues: Appcues {
    init() {
        super.init(config: Appcues.Config(accountID: "00000", applicationID: "abc"))
    }

    override init(config: Config) {
        super.init(config: config)
    }

    override func initializeContainer() {

        container.register(Appcues.self, value: self)
        container.register(Appcues.Config.self, value: config)
        container.register(AnalyticsPublishing.self, value: self)

        // TODO: build out the service mocks and registration
        container.register(DataStoring.self, value: storage)
        container.register(ExperienceLoading.self, value: experienceLoader)
        container.register(ExperienceRendering.self, value: experienceRenderer)
        container.register(UIDebugging.self, value: debugger)
        container.register(SessionMonitoring.self, value: sessionMonitor)
        container.register(ActivityProcessing.self, value: activityProcessor)
        container.register(DeeplinkHandling.self, value: deeplinkHandler)

        // dependencies that are not mocked
        container.registerLazy(NotificationCenter.self, initializer: NotificationCenter.init)
        container.registerLazy(UIKitScreenTracker.self, initializer: UIKitScreenTracker.init)

    }

    var onIdentify: ((String, [String: Any]?) -> Void)?
    override func identify(userID: String, properties: [String : Any]? = nil) {
        onIdentify?(userID, properties)
        super.identify(userID: userID, properties: properties)
    }

    var onTrack: ((String, [String: Any]?) -> Void)?
    override func track(name: String, properties: [String : Any]? = nil) {
        onTrack?(name, properties)
        super.track(name: name, properties: properties)
    }

    var onScreen: ((String, [String: Any]?) -> Void)?
    override func screen(title: String, properties: [String : Any]? = nil) {
        onScreen?(title, properties)
        super.screen(title: title, properties: properties)
    }

    var storage = MockStorage()
    var experienceLoader = MockExperienceLoader()
    var experienceRenderer = MockExperienceRenderer()
    var sessionMonitor = MockSessionMonitor()
    var activityProcessor = MockActivityProcessor()
    var debugger = MockDebugger()
    var deeplinkHandler = MockDeeplinkHandler()
}

class MockStorage: DataStoring {
    var deviceID: String = "device-id"
    var userID: String = "user-id"
    var groupID: String?
    var isAnonymous: Bool = false
    var lastContentShownAt: Date?
}

class MockExperienceLoader: ExperienceLoading {

    var onLoad: ((String, Bool) -> Void)?

    func load(experienceID: String, published: Bool) {
        onLoad?(experienceID, published)
    }
}

class MockExperienceRenderer: ExperienceRendering {

    var onShowExperience: ((Experience, Bool) -> Void)?
    var onShowStep: ((StepReference) -> Void)?
    var onDismissCurrentExperience: (() -> Void)?

    func show(experience: Experience, published: Bool) {
        onShowExperience?(experience, published)
    }

    func show(stepInCurrentExperience stepRef: StepReference) {
        onShowStep?(stepRef)
    }

    func dismissCurrentExperience() {
        onDismissCurrentExperience?()
    }
}

class MockSessionMonitor: SessionMonitoring {
    var sessionID: UUID?
    var isActive: Bool = true
    var onStart: (() -> Void)?
    var onReset: (() -> Void)?

    func start() {
        onStart?()
    }

    func reset() {
        onReset?()
    }
}

class MockActivityProcessor: ActivityProcessing {

    var onProcess: ((Activity, Bool, ((Result<Taco, Error>) -> Void)?) -> Void)?
    var onFlush: (() -> Void)?

    func process(_ activity: Activity, sync: Bool, completion: ((Result<Taco, Error>) -> Void)?) {
        onProcess?(activity, sync, completion)
    }

    func flush() {
        onFlush?()
    }
}

class MockDebugger: UIDebugging {

    var onShow: (() -> Void)?
    func show() {
        onShow?()
    }
}

class MockDeeplinkHandler: DeeplinkHandling {

    var onDidHandleURL: ((URL) -> Bool)?
    func didHandleURL(_ url: URL) -> Bool {
        return onDidHandleURL?(url) ?? false
    }
}
