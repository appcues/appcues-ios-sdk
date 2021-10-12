//
//  Networking.swift
//  Appcues
//
//  Created by Matt on 2021-10-07.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal class Networking {
    let config: Config

    init(config: Config) {
        self.config = config
    }

    func get<T: Decodable>(from endpoint: Endpoint, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        guard let requestURL = url(for: endpoint) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"

        handleRequest(request, completion: completion)
    }

    func post<T: Decodable>(to endpoint: Endpoint, body: Data, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        guard let requestURL = url(for: endpoint) else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = body

        handleRequest(request, completion: completion)
    }

    private func handleRequest<T: Decodable>(_ urlRequest: URLRequest, completion: @escaping (_ result: Result<T, Error>) -> Void) {
        let dataTask = config.urlSession.dataTask(with: urlRequest) { data, response, error in
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

        dataTask.resume()
    }

    private func url(for endpoint: Endpoint) -> URL? {
        URL(string: "https://\(config.apiHost)\(endpoint.path)")
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
