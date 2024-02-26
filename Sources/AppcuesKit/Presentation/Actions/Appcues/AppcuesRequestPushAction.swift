//
//  AppcuesRequestPushAction.swift
//  AppcuesKitTests
//
//  Created by Matt on 2024-02-26.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation
import UserNotifications

@available(iOS 13.0, *)
internal class AppcuesRequestPushAction: AppcuesExperienceAction {

    static let type = "@appcues/request-push"

    private weak var appcues: Appcues?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else {
            completion()
            return
        }

        let resultHandler: (Bool, Error?) -> Void = { _, error in
            if let error = error {
                appcues.config.logger.error("@appcues/request-push failed with %{public}@", error.localizedDescription)
            }

            let pushMonitor = appcues.container.resolve(PushMonitoring.self)
            let analyticsPublisher = appcues.container.resolve(AnalyticsPublishing.self)

            pushMonitor.refreshPushStatus { _ in
                analyticsPublisher.publish(TrackingUpdate(
                    type: .event(name: Events.Device.deviceUpdated.rawValue, interactive: false),
                    isInternal: true
                ))

                completion()
            }
        }

        // Skip call to UNUserNotificationCenter.current() in tests to avoid crashing in package tests
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil else {
            resultHandler(false, AppcuesTraitError(description: "Executing in test environment"))
            return
        }
        #endif

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: resultHandler)
    }
}
