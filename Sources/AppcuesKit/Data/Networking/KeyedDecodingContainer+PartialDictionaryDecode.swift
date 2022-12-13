//
//  KeyedDecodingContainer+PartialDictionaryDecode.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-10.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {

    /// Partially decode a JSON dictionary, leaving nested objects to be decoded to proper model types later on
    /// when more type info may be known.
    func partialDictionaryDecode(forKey key: K) throws -> [String: KeyedDecodingContainer<JSONCodingKeys>] {
        try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key).partialDictionaryDecode()
    }
}

extension KeyedDecodingContainer where K == JSONCodingKeys {
    func partialDictionaryDecode() throws -> [String: KeyedDecodingContainer<JSONCodingKeys>] {
        allKeys.reduce(into: [:]) { dict, key in
            dict[key.stringValue] = self
        }
    }
}
