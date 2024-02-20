//
//  NetworkingError.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal enum NetworkingError: Error {
    case invalidURL
    case noData
    case nonSuccessfulStatusCode(Int)
}
