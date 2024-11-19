//
//  DeepLinkVerifier.swift
//  AppcuesKit
//
//  Created by Matt on 2023-10-10.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit
import Combine

internal class DeepLinkVerifier {
    let title = "Appcues Deep Link"
    let applicationID: String

    /// Unique value to pass through a deep link to verify handling.
    private var deepLinkVerificationToken: String?

    var urlTypes: [[String: Any]]? { Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] }

    private let subject = PassthroughSubject<StatusItem, Never>()
    var publisher: AnyPublisher<StatusItem, Never> { subject.eraseToAnyPublisher() }

    init(applicationID: String) {
        self.applicationID = applicationID
    }

    func verifyDeepLink(token: UUID = UUID()) {
        subject.send(StatusItem(status: .pending, title: title, subtitle: nil))

        guard infoPlistContainsScheme() else {
            subject.send(StatusItem(status: .unverified, title: title, subtitle: "Error 1: CFBundleURLSchemes value missing"))
            return
        }

        verifyDeepLinkHandling(token: token.uuidString)
    }

    private func infoPlistContainsScheme() -> Bool {
        guard let urlTypes = urlTypes else { return false }

        return urlTypes
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
            .contains { $0 == "appcues-\(applicationID)" }
    }

    private func verifyDeepLinkHandling(token: String) {
        guard let url = URL(string: "appcues-\(applicationID)://sdk/verify/\(token)") else {
            subject.send(StatusItem(status: .unverified, title: title, subtitle: "Error 0: Failed to set up verification"))
            return
        }

        deepLinkVerificationToken = token

        UIApplication.shared.open(url, options: [:])

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.deepLinkVerificationToken != nil {
                self.subject.send(StatusItem(status: .unverified, title: self.title, subtitle: "Error 2: Appcues SDK not receiving links"))
                self.deepLinkVerificationToken = nil
            }
        }
    }

    func receivedVerification(token: String) {
        if token == deepLinkVerificationToken {
            subject.send(StatusItem(status: .verified, title: title, subtitle: nil))
        } else {
            subject.send(StatusItem(status: .unverified, title: title, subtitle: "Error 3: Unexpected result"))
        }

        deepLinkVerificationToken = nil
    }
}
