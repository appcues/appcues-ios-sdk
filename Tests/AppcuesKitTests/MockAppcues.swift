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

    }
}
