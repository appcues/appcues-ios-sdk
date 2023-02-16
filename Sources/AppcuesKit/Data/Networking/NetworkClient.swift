//
//  NetworkClient.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol Networking: AnyObject {
    func get<T: Decodable>(from endpoint: Endpoint,
                           authorization: Authorization?,
                           completion: @escaping (_ result: Result<T, Error>) -> Void)

    func post<T: Decodable>(to endpoint: Endpoint,
                            authorization: Authorization?,
                            body: Data,
                            requestId: UUID?,
                            completion: @escaping (_ result: Result<T, Error>) -> Void)

    func post(to endpoint: Endpoint,
              authorization: Authorization?,
              body: Data?,
              completion: @escaping (_ result: Result<Void, Error>) -> Void)

    func put(to endpoint: Endpoint,
             authorization: Authorization?,
             body: Data,
             contentType: String,
             completion: @escaping (_ result: Result<Void, Error>) -> Void)

}

internal class NetworkClient: Networking {

    private let config: Appcues.Config
    private let storage: DataStoring

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
    }

    func get<T: Decodable>(from endpoint: Endpoint,
                           authorization: Authorization?,
                           completion: @escaping (_ result: Result<T, Error>) -> Void) {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.authorize(authorization)

        handleRequest(request, requestId: nil, completion: completion)
    }

    func post<T: Decodable>(to endpoint: Endpoint,
                            authorization: Authorization?,
                            body: Data,
                            requestId: UUID?,
                            completion: @escaping (_ result: Result<T, Error>) -> Void) {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.authorize(authorization)

        handleRequest(request, requestId: requestId, completion: completion)
    }

    func post(to endpoint: Endpoint,
              authorization: Authorization?,
              body: Data?,
              completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.authorize(authorization)

        handleRequest(request, completion: completion)
    }

    func put(to endpoint: Endpoint,
             authorization: Authorization?,
             body: Data,
             contentType: String,
             completion: @escaping (Result<Void, Error>) -> Void) {

        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.authorize(authorization)

        handleRequest(request, completion: completion)
    }

    // version that decodes the response into the given type T
    private func handleRequest<T: Decodable>(_ urlRequest: URLRequest,
                                             requestId: UUID?,
                                             completion: @escaping (_ result: Result<T, Error>) -> Void) {
        SdkMetrics.requested(requestId)
        let dataTask = config.urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            SdkMetrics.responded(requestId)
            if let url = response?.url?.absoluteString, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                let data = String(data: data ?? Data(), encoding: .utf8) ?? ""

                self?.config.logger.debug("RESPONSE: %{public}d %{public}s\n%{private}s", statusCode, url, data)
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !httpResponse.isSuccessStatusCode {
                completion(.failure(NetworkingError.nonSuccessfulStatusCode(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                return
            }

            do {
                let responseObject = try Self.decoder.decode(T.self, from: data)
                completion(.success(responseObject))
            } catch {
                completion(.failure(error))
            }
        }

        if let method = urlRequest.httpMethod, let url = urlRequest.url?.absoluteString {
            let data = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
            config.logger.debug("REQUEST: %{public}s %{public}s\n%{private}s", method, url, data)
        }

        dataTask.resume()
    }

    // version that does not decode any response object, assumes empty or discards
    private func handleRequest(_ urlRequest: URLRequest,
                               completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        let dataTask = config.urlSession.dataTask(with: urlRequest) { [weak self] _, response, error in
            if let url = response?.url?.absoluteString, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                self?.config.logger.debug("RESPONSE: %{public}d %{public}s", statusCode, url)
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !httpResponse.isSuccessStatusCode {
                completion(.failure(NetworkingError.nonSuccessfulStatusCode(httpResponse.statusCode)))
                return
            }

            completion(.success(()))
        }

        if let method = urlRequest.httpMethod, let url = urlRequest.url?.absoluteString {
            let data = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
            config.logger.debug("REQUEST: %{public}s %{public}s\n%{private}s", method, url, data)
        }

        dataTask.resume()
    }

}

extension NetworkClient {
    // swiftlint:disable force_unwrapping
    static let defaultAPIHost = URL(string: "https://api.appcues.net")!
    static let sdkSettingsHost = URL(string: "https://fast.appcues.com")!
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
