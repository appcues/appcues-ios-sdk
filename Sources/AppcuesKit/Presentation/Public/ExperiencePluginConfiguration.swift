//
//  ExperiencePluginConfiguration.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/19/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

@objc
public class ExperiencePluginConfiguration: NSObject {

    private var decoder: PluginDecoder

    init(_ decoder: PluginDecoder) {
        self.decoder = decoder
    }

    public func decode<T: Decodable>(_ type: T.Type) -> T? {
        return decoder.decode(type)
    }
}
