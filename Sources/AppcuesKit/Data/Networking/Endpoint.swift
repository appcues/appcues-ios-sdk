//
//  Endpoint.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// Endpoints in the Appcues API.
internal enum APIEndpoint: Endpoint {
    case activity(userID: String)
    case qualify(userID: String)
    case content(experienceID: String, queryItems: [URLQueryItem])
    case preview(experienceID: String, queryItems: [URLQueryItem])
    case health

    /// URL fragments that that are appended to the `Config.apiHost` to make the URL for a network request.
    func url(config: Appcues.Config, storage: DataStoring) -> URL? {
        guard var components = URLComponents(url: config.apiHost, resolvingAgainstBaseURL: false) else { return nil }

        switch self {
        case let .activity(userID):
            components.path = "/v1/accounts/\(config.accountID)/users/\(userID)/activity"
        case let .qualify(userID):
            components.path = "/v1/accounts/\(config.accountID)/users/\(userID)/qualify"
        case let .content(experienceID, queryItems):
            components.path = "/v1/accounts/\(config.accountID)/users/\(storage.userID)/experience_content/\(experienceID)"
            components.queryItems = queryItems
        case let .preview(experienceID, queryItems):
            // optionally include the userID, if one exists, to allow for a personalized preview capability
            if storage.userID.isEmpty {
                components.path = "/v1/accounts/\(config.accountID)/experience_preview/\(experienceID)"
            } else {
                components.path = "/v1/accounts/\(config.accountID)/users/\(storage.userID)/experience_preview/\(experienceID)"
            }
            components.queryItems = queryItems
        case .health:
            components.path = "/healthz"
        }

        return components.url
    }
}

/// Mobile SDK configuration endpoints, providing links to other services.
internal enum SettingsEndpoint: Endpoint {
    case settings

    func url(config: Appcues.Config, storage: DataStoring) -> URL? {
        guard var components = URLComponents(url: config.settingsHost, resolvingAgainstBaseURL: false) else { return nil }

        switch self {
        case .settings:
            components.path = "/bundle/accounts/\(config.accountID)/mobile/settings"
        }

        return components.url
    }
}

/// Appcues Customer API endpoints.
internal enum CustomerAPIEndpoint: Endpoint {
    case preSignedImageUpload(host: URL, filename: String)
    case screenCapture(host: URL)

    var host: URL {
        switch self {
        case let .preSignedImageUpload(host, _):
            return host
        case let .screenCapture(host):
            return host
        }
    }

    func url(config: Appcues.Config, storage: DataStoring) -> URL? {
        guard var components = URLComponents(url: host, resolvingAgainstBaseURL: false) else { return nil }

        switch self {
        case let .preSignedImageUpload(_, filename):
            components.path = "/v1/accounts/\(config.accountID)/mobile/\(config.applicationID)/pre-upload-screenshot"
            components.query = "name=\(filename)"
        case .screenCapture:
            components.path = "/v1/accounts/\(config.accountID)/mobile/\(config.applicationID)/screens"
        }

        return components.url
    }
}

/// Endpoint where the full URL is provided, such as the pre-signed image upload endpoint
internal struct URLEndpoint: Endpoint {
    let url: URL

    func url(config: Appcues.Config, storage: DataStoring) -> URL? {
        return url
    }
}

internal protocol Endpoint {
    func url(config: Appcues.Config, storage: DataStoring) -> URL?
}
