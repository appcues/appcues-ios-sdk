//
//  AppcuesExperiencePluginConfiguration.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/19/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// An object that decodes instances of a plugin configuration from an Experience JSON model.
@objc
public class AppcuesExperiencePluginConfiguration: NSObject {

    /// Context in which a plugin can be applied.
    @objc
    public enum Level: Int {
        /// A plugin defined on an entire experience.
        case experience
        /// A plugin defined on a group of steps in an experience.
        case group
        /// A plugin defined on single step in an experience.
        case step
    }

    private var decoder: PluginDecoder

    /// The context where the plugin was defined.
    public let level: Level

    init(_ decoder: PluginDecoder, level: Level) {
        self.decoder = decoder
        self.level = level
    }

    /// Returns a value of the type you specify, decoded from a JSON object.
    /// - Parameter type: The type of the value to decode from the supplied plugin decoder.
    /// - Returns: A value of the specified type, if the decoder can parse the data.
    public func decode<T: Decodable>(_ type: T.Type) -> T? {
        return decoder.decode(type)
    }
}
