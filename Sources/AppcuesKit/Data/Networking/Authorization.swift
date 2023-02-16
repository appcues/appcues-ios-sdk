//
//  Authorization.swift
//  AppcuesKit
//
//  Created by James Ellis on 2/16/23.
//  Copyright © 2023 Appcues. All rights reserved.
//
import Foundation

internal enum Authorization {
    case bearer(String)

    init?(bearerToken: String?) {
        guard let bearerToken = bearerToken else { return nil }
        self = .bearer(bearerToken)
    }
}

extension URLRequest {
    mutating func authorize(_ auth: Authorization?) {
        guard let auth = auth else { return }
        switch auth {
        case let .bearer(token):
            self.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
