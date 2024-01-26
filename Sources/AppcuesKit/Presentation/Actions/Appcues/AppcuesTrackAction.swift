//
//  AppcuesTrackAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesTrackAction: AppcuesExperienceAction {
    struct Config {
        let eventName: String
        let attributes: [String: Any]?
    }

    static let type = "@appcues/track"

    private weak var appcues: Appcues?

    let eventName: String
    let attributes: [String: Any]?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.eventName = config.eventName
        self.attributes = config.attributes
    }

    func execute(completion: ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        appcues.track(name: eventName, properties: attributes)
        completion()
    }
}

@available(iOS 13.0, *)
extension AppcuesTrackAction.Config: Decodable {

    private enum CodingKeys: String, CodingKey {
           case eventName
           case attributes
    }

    // Custom decoding for this one - we want to extract the eventName and then for the attributes
    // we handle it as a nestedContainer then we trim the set to only those of supported data types
    // then store in the resulting attributes dictionary
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventName = try container.decode(String.self, forKey: .eventName)

        if let attributesContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .attributes) {
            var dict: [String: Any] = [:]

            attributesContainer.allKeys.forEach { key in
                if let boolValue = try? attributesContainer.decode(Bool.self, forKey: key) {
                    dict[key.stringValue] = boolValue
                } else if let stringValue = try? attributesContainer.decode(String.self, forKey: key) {
                    dict[key.stringValue] = stringValue
                } else if let intValue = try? attributesContainer.decode(Int.self, forKey: key) {
                    dict[key.stringValue] = intValue
                } else if let doubleValue = try? attributesContainer.decode(Double.self, forKey: key) {
                    dict[key.stringValue] = doubleValue
                } else {
                    // not a supported type
                }
            }
            self.attributes = dict
        } else {
            attributes = nil
        }
    }
}
