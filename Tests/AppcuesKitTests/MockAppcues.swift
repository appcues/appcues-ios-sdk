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
        container.register(SessionMonitoring.self, value: sessionMonitor)
        container.register(ActivityProcessing.self, value: activityProcessor)

        container.registerLazy(NotificationCenter.self, initializer: NotificationCenter.init)

    }

    var storage = MockStorage()
    var experienceLoader = MockExperienceLoader()
    var experienceRenderer = MockExperienceRenderer()
    var sessionMonitor = MockSessionMonitor()
    var activityProcessor = MockActivityProcessor()
}

class MockStorage: DataStoring {
    var deviceID: String = "device-id"
    var userID: String = "user-id"
    var groupID: String?
    var isAnonymous: Bool = false
    var lastContentShownAt: Date?
}

class MockExperienceLoader: ExperienceLoading {

    var onLoad: ((String) -> Void)?

    func load(contentID: String) {
        onLoad?(contentID)
    }
}

class MockExperienceRenderer: ExperienceRendering {

    var onShowExperience: ((Experience) -> Void)?
    var onShowStep: ((StepReference) -> Void)?
    var onShowFlow: ((Flow) -> Void)?
    var onDismissCurrentExperience: (() -> Void)?

    func show(experience: Experience) {
        onShowExperience?(experience)
    }

    func show(stepInCurrentExperience stepRef: StepReference) {
        onShowStep?(stepRef)
    }

    func show(flow: Flow) {
        onShowFlow?(flow)
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
