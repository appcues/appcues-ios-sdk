//
//  Appcues.swift
//  Appcues
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

public class Appcues {

    /// Temporary internal log of API calls
    var log: [String] = []

    public init() {
    }

    public func identify(userId: String, traits: [String: String]) {
        log.append("Appcues.identify(userId: \(userId))")
    }

    public func track(event: String, properties: [String: String]) {
        log.append("Appcues.track(event: \(event))")
    }

    public func screen(title: String, properties: [String: String]) {
        log.append("Appcues.screen(title: \(title))")
    }
}
