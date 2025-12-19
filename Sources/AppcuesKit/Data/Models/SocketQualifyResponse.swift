//
//  SocketQualifyResponse.swift
//  AppcuesKit
//
//  Created by Appcues on 2025-01-XX.
//  Copyright © 2025 Appcues. All rights reserved.
//

import Foundation

/// API response structure for a socket `phx_reply` event.
/// Identical to `QualifyResponse` but decodes `content` key instead of `experiences`.
internal struct SocketQualifyResponse {
    let experiences: [LossyExperience]
    let performedQualification: Bool
    let qualificationReason: QualifyResponse.QualificationReason?
    let experiments: [Experiment]?
    let metrics: QualifyResponse.Metrics?
}

extension SocketQualifyResponse: Decodable {
    private enum CodingKeys: CodingKey {
        case content
        case performedQualification
        case qualificationReason
        case experiments
        case metrics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Default to true if not present, matching server behavior
        performedQualification =
            (try? container.decode(Bool.self, forKey: .performedQualification)) ?? true
        // Optional try so that an unknown reason is treated as nil rather than failing the decode.
        qualificationReason = try? container.decode(
            QualifyResponse.QualificationReason.self, forKey: .qualificationReason)
        experiments = try? container.decode([Experiment].self, forKey: .experiments)
        metrics = try? container.decode(QualifyResponse.Metrics.self, forKey: .metrics)

        // special handling for content (socket uses "content" instead of "experiences")
        // to be lenient of malformed JSON for any particular item in the array, and preserve
        // any valid items in priority order - don't let one bad response item fail the entire qualification response
        var decodedExperiences: [LossyExperience] = []
        if var experienceContainer = try? container.nestedUnkeyedContainer(forKey: .content) {
            if let count = experienceContainer.count {
                decodedExperiences.reserveCapacity(count)
            }

            var errorMessage: String?

            while !experienceContainer.isAtEnd {
                do {
                    let experience = try experienceContainer.decode(Experience.self)
                    decodedExperiences.append(.decoded(experience))
                    continue
                } catch let error as DecodingError {
                    errorMessage = error.decodingErrorMessage
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

extension SocketQualifyResponse {
    /// Convert to `QualifyResponse` for compatibility with existing code
    func toQualifyResponse() -> QualifyResponse {
        return QualifyResponse(
            experiences: experiences,
            performedQualification: performedQualification,
            qualificationReason: qualificationReason,
            experiments: experiments,
            metrics: metrics
        )
    }
}
