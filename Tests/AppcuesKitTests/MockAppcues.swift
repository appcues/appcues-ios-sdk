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
    override init(config: Config) {
        super.init(config: config)
    }

    override func initializeContainer() {

        container.register(Appcues.self, value: self)
        container.register(Appcues.Config.self, value: config)
        container.register(AnalyticsPublishing.self, value: self)

        // TODO: build out the service mocks and registration
        container.register(DataStoring.self, value: storage)
        container.register(ActivityProcessing.self, value: activityProcessor)

    }

    var storage: MockStorage = MockStorage()
    var activityProcessor: MockActivityProcessor = MockActivityProcessor()
}

class MockStorage: DataStoring {
    var deviceID: String = "device-id"
    var userID: String = "user-id"
    var groupID: String?
    var isAnonymous: Bool = false
    var lastContentShownAt: Date?
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
