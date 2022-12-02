//
//  QualifyResponse.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// API repsonse stucture for a `/qualify` request.
internal struct QualifyResponse {

    enum QualificationReason: String, Decodable {
        case forced = "forced"
        case eventTrigger = "event_trigger"
        case pageView = "page_view"
        case screenView = "screen_view"
    }

    /// Mobile experience JSON structure.
    let experiences: [LossyExperience]
    let performedQualification: Bool
    let qualificationReason: QualificationReason?
    let experiments: [Experiment]?
}

extension QualifyResponse: Decodable {
    private enum CodingKeys: CodingKey {
        case experiences
        case performedQualification
        case qualificationReason
        case experiments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        performedQualification = try container.decode(Bool.self, forKey: .performedQualification)
        // Optional try so that an unknown reason is treated as nil rather than failing the decode.
        qualificationReason = try? container.decode(QualificationReason.self, forKey: .qualificationReason)
        experiments = try? container.decode([Experiment].self, forKey: .experiments)

        // special handling for experiences, to be lenient of malformed JSON for any particular
        // item in the array, and preserve any valid items in priority order - don't let one bad
        // response item fail the entire qualification response
        var decodedExperiences: [LossyExperience] = []
        if var experienceContainer = try? container.nestedUnkeyedContainer(forKey: .experiences) {
            if let count = experienceContainer.count {
                decodedExperiences.reserveCapacity(count)
            }

            var errorMessage: String?

            while !experienceContainer.isAtEnd {
                do {
                    let experience = try experienceContainer.decode(Experience.self)
                    decodedExperiences.append(.decoded(experience))
                    continue
                } catch let DecodingError.dataCorrupted(context) {
                    errorMessage = "\(context)"
                } catch let DecodingError.keyNotFound(key, context) {
                    errorMessage = "key '\(key)' not found: \(context.debugDescription) codingPath: \(context.codingPath)"
                } catch let DecodingError.valueNotFound(value, context) {
                    errorMessage = "value '\(value)' not found: \(context.debugDescription) codingPath: \(context.codingPath)"
                } catch let DecodingError.typeMismatch(type, context) {
                    errorMessage = "type '\(type)' mismatch: \(context.debugDescription) codingPath: \(context.codingPath)"
                } catch {
                    errorMessage = "error: \(error)"
                }

                // if we get here, it means we failed normal decoding. Try to decode the minimal
                // info needed to report a flow issue that we can troubleshoot
                if var element = try? experienceContainer.decode(FailedExperience.self) {
                    element.error = errorMessage
                    decodedExperiences.append(.failed(element))
                } else {
                    // cannot decode anything at all about this experience, skip it
                    try experienceContainer.skip()
                }
            }
        }
        experiences = decodedExperiences
    }
}

extension Array where Element == LossyExperience {
    func parsed() -> [Experience] {
        return self.compactMap {
            if case let .decoded(experience) = $0 {
                return experience
            }
            return nil
        }
    }
}
