//
//  NetworkClient.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol Networking: AnyObject {
    func get<T: Decodable>(from endpoint: Endpoint, completion: @escaping (_ result: Result<T, Error>) -> Void)
    func post<T: Decodable>(to endpoint: Endpoint, body: Data, completion: @escaping (_ result: Result<T, Error>) -> Void)
}

internal class NetworkClient: Networking {
    private let config: Appcues.Config
    private let storage: DataStoring

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
    }

    func get<T: Decodable>(from endpoint: Endpoint, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"

        handleRequest(request, completion: completion)
    }

    func post<T: Decodable>(to endpoint: Endpoint, body: Data, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        guard let requestURL = endpoint.url(config: config, storage: storage) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body

        handleRequest(request, completion: completion)
    }

    private func handleRequest<T: Decodable>(_ urlRequest: URLRequest, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        let dataTask = config.urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
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
}

extension NetworkClient {
    // swiftlint:disable:next force_unwrapping
    static let defaultAPIHost = URL(string: "https://api.appcues.net")!

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
        encoder.dateEncodingStrategy = .custom { (date, encoder) throws in
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

private extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1_000.0).rounded())
    }
}
