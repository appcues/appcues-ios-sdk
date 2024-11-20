//
//  NetworkClient.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol Networking: AnyObject {
    func get<T: Decodable>(
        from endpoint: Endpoint,
        authorization: Authorization?
    ) async throws -> T
    func post<T: Decodable>(
        to endpoint: Endpoint,
        authorization: Authorization?,
        body: Data?,
        requestId: UUID?
    ) async throws -> T
    func post(
        to endpoint: Endpoint,
        authorization: Authorization?,
        body: Data?
    ) async throws
    func put(
        to endpoint: Endpoint,
        authorization: Authorization?,
        body: Data,
        contentType: String
    ) async throws
}

internal class NetworkClient: Networking {
    private let config: Appcues.Config
    private let storage: DataStoring

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
    }

    func get<T: Decodable>(from endpoint: any Endpoint, authorization: Authorization?) async throws -> T {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            throw NetworkingError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.authorize(authorization)

        return try await handleRequest(request, requestId: nil)
    }

    func post<T: Decodable>(to endpoint: any Endpoint, authorization: Authorization?, body: Data?, requestId: UUID?) async throws -> T {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            throw NetworkingError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.authorize(authorization)

        return try await handleRequest(request, requestId: requestId)
    }

    func post(to endpoint: any Endpoint, authorization: Authorization?, body: Data?) async throws {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            throw NetworkingError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.authorize(authorization)

        return try await handleRequest(request)
    }

    func put(to endpoint: any Endpoint, authorization: Authorization?, body: Data, contentType: String) async throws {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            throw NetworkingError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.authorize(authorization)

        return try await handleRequest(request)
    }

    // version that decodes the response into the given type T
    private func handleRequest<T: Decodable>(_ urlRequest: URLRequest, requestId: UUID?) async throws -> T {
        SdkMetrics.requested(requestId)

        if let method = urlRequest.httpMethod, let url = urlRequest.url?.absoluteString {
            let data = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
            config.logger.debug("REQUEST: %{public}@ %{public}@\n%{private}@", method, url, data)
        }

        let (data, response) = try await config.urlSession.data(for: urlRequest)

        SdkMetrics.responded(requestId)
        let url = (response.url ?? urlRequest.url)?.absoluteString ?? "<unknown>"
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let logData = String(data: data, encoding: .utf8) ?? ""

        config.logger.debug("RESPONSE: %{public}d %{public}@\n%{private}@", statusCode, url, logData)

        if let httpResponse = response as? HTTPURLResponse, !httpResponse.isSuccessStatusCode {
            throw NetworkingError.nonSuccessfulStatusCode(httpResponse.statusCode, data)
        }

        let responseObject = try Self.decoder.decode(T.self, from: data)
        return responseObject
    }

    // version that does not decode any response object, assumes empty or discards
    private func handleRequest(_ urlRequest: URLRequest) async throws {
        if let method = urlRequest.httpMethod, let url = urlRequest.url?.absoluteString {
            let data = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
            config.logger.debug("REQUEST: %{public}@ %{public}@\n%{private}@", method, url, data)
        }

        let (data, response) = try await config.urlSession.data(for: urlRequest)

        let url = (response.url ?? urlRequest.url)?.absoluteString ?? "<unknown>"
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let logData = String(data: data, encoding: .utf8) ?? ""

        config.logger.debug("RESPONSE: %{public}d %{public}@\n%{private}@", statusCode, url, logData)

        if let httpResponse = response as? HTTPURLResponse, !httpResponse.isSuccessStatusCode {
            throw NetworkingError.nonSuccessfulStatusCode(httpResponse.statusCode, data)
        }
    }

}

extension NetworkClient {
    // swiftlint:disable force_unwrapping
    static let defaultAPIHost = URL(string: "https://api.appcues.net")!
    static let defaultSettingsHost = URL(string: "https://fast.appcues.com")!
    // swiftlint:enable force_unwrapping

    static var defaultURLSession: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 5
        configuration.httpAdditionalHeaders = [
            "Content-Type": "application/json; charset=utf-8"
        ]

        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        return session
    }

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder throws in
            var container = encoder.singleValueContainer()
            try container.encode(date.millisecondsSince1970)
        }
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension Date {
    var millisecondsSince1970: Double {
        return (self.timeIntervalSince1970 * 1_000.0).rounded()
    }
}

private extension Error {
    var data: Data? {
        localizedDescription.data(using: .utf8)
    }
}

private extension Data {
    static var empty: Data {
        "<no data or error>".data(using: .utf8) ?? Data()
    }
}
