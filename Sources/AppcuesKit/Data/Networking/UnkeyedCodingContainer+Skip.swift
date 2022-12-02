// swiftlint:disable:this file_name
//
//  UnkeyedCodingContainer+Skip.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/2/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

private struct Empty: Decodable { }

extension UnkeyedDecodingContainer {
    mutating func skip() throws {
        _ = try decode(Empty.self)
    }
}
