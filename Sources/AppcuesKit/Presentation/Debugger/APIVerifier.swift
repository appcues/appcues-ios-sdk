//
//  APIVerifier.swift
//  AppcuesKit
//
//  Created by Matt on 2023-10-10.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation
import Combine

internal class APIVerifier {
    static let title = "Connected to Appcues"
    let networking: Networking

    private let subject = PassthroughSubject<StatusItem, Never>()
    var publisher: AnyPublisher<StatusItem, Never> { subject.eraseToAnyPublisher() }

    init(networking: Networking) {
        self.networking = networking
    }

    @MainActor
    func verifyAPI() async {
        subject.send(StatusItem(status: .pending, title: APIVerifier.title))

        do {
            let _: ActivityResponse = try await networking.get(from: APIEndpoint.health, authorization: nil)
            subject.send(StatusItem(status: .verified, title: APIVerifier.title))
        } catch {
            subject.send(StatusItem(
                status: .unverified,
                title: APIVerifier.title,
                subtitle: error.localizedDescription,
                detailText: "\(error)"
            ))
        }
    }
}
