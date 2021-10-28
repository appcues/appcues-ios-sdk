//
//  Networking.swift
//  Appcues
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import Combine

internal class Networking {
    let config: Appcues.Config

    init(config: Appcues.Config) {
        self.config = config
    }

    func get<T: Decodable>(from endpoint: Endpoint) -> AnyPublisher<T, Error> {
        guard let requestURL = endpoint.url(with: config) else {
            return Fail<T, Error>(error: NetworkingError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"

        return handleRequest(request)
    }

    func post<T: Decodable>(to endpoint: Endpoint, body: Data) -> AnyPublisher<T, Error> {
        guard let requestURL = endpoint.url(with: config) else {
            return Fail<T, Error>(error: NetworkingError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body

        return handleRequest(request)
    }

    private func handleRequest<T: Decodable>(_ urlRequest: URLRequest) -> AnyPublisher<T, Error> {

        if let method = urlRequest.httpMethod, let url = urlRequest.url?.absoluteString {
            let data = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
            config.logger.debug("REQUEST: %{public}s %{public}s\n%{private}s", method, url, data)
        }

        // TODO: re-add response logging
//        if let url = response?.url?.absoluteString, let statusCode = (response as? HTTPURLResponse)?.statusCode {
//            let data = String(data: data ?? Data(), encoding: .utf8) ?? ""
//
//            self?.config.logger.debug("RESPONSE: %{public}d %{public}s\n%{private}s", statusCode, url, data)
//        }

        return config.urlSession
            .dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse, !httpResponse.isSuccessStatusCode {
                    throw NetworkingError.nonSuccessfulStatusCode(httpResponse.statusCode)
                }

                return data
            }
            .decode(type: T.self, decoder: Self.decoder)
            .eraseToAnyPublisher()
    }
}

extension Networking {
    static let defaultAPIHost = "api.appcues.com"

    static var defaultURLSession: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 30
        configuration.httpAdditionalHeaders = [
            "Content-Type": "application/json; charset=utf-8"
        ]

        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        return session
    }

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
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

extension Subscribers.Completion {
    func printIfError() {
        if case let .failure(error) = self {
            print(error)
        }
    }
}
