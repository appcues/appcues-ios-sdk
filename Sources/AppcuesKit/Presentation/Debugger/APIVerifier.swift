//
//  APIVerifier.swift
//  AppcuesKit
//
//  Created by Matt on 2023-10-10.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
internal class APIVerifier {
    let title = "Connected to Appcues"
    let networking: Networking

    let subject = PassthroughSubject<StatusItem, Never>()

    init(networking: Networking) {
        self.networking = networking
    }

    func verifyAPI() {
        subject.send(StatusItem(status: .pending, title: title))

        networking.get(from: APIEndpoint.health, authorization: nil) { [weak self] (result: Result<ActivityResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.subject.send(StatusItem(status: .verified, title: self?.title ?? ""))
                case .failure(let error):
                    self?.subject.send(StatusItem(
                        status: .unverified,
                        title: self?.title ?? "",
                        subtitle: error.localizedDescription,
                        detailText: "\(error)"
                    ))
                }
            }
        }
    }
}
