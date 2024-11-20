//
//  AppcuesRequestPushAction.swift
//  AppcuesKitTests
//
//  Created by Matt on 2024-02-26.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation
import UserNotifications

internal class AppcuesRequestPushAction: AppcuesExperienceAction {

    static let type = "@appcues/request-push"

    private weak var appcues: Appcues?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues
    }

    func execute() async throws {
        guard let appcues = appcues else { throw AppcuesTraitError(description: "No appcues instance") }

        let resultHandler: (Bool, Error?) async -> Void = { _, error in
            if let error = error {
                appcues.config.logger.error("@appcues/request-push failed with %{public}@", error.localizedDescription)
            }
            let pushMonitor = appcues.container.resolve(PushMonitoring.self)
            await pushMonitor.refreshPushStatus()
        }

        // Skip call to UNUserNotificationCenter.current() in tests to avoid crashing in package tests
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil else {
            await resultHandler(false, AppcuesTraitError(description: "Executing in test environment"))
            return
        }
        #endif

        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let result = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await resultHandler(result, nil)
        } catch {
            await resultHandler(false, error)
        }
    }
}
