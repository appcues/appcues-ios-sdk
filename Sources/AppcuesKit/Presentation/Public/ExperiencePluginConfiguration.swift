//
//  ExperiencePluginConfiguration.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/19/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// An object that decodes instances of a plugin configuration from an Experience JSON model.
@objc
public class ExperiencePluginConfiguration: NSObject {

    private var decoder: PluginDecoder

    init(_ decoder: PluginDecoder) {
        self.decoder = decoder
    }

    /// Returns a value of the type you specify, decoded from a JSON object.
    /// - Parameter type: The type of the value to decode from the supplied plugin decoder.
    /// - Returns: A value of the specified type, if the decoder can parse the data.
    public func decode<T: Decodable>(_ type: T.Type) -> T? {
        return decoder.decode(type)
    }
}
