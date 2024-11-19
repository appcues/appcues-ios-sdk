//
//  StatusItem.swift
//  AppcuesKit
//
//  Created by Matt on 2023-09-27.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

internal struct StatusItem: Identifiable {
    let id: UUID
    var status: Status
    let title: String
    var subtitle: String?
    var detailText: String?

    init(
        status: Status,
        title: String,
        subtitle: String? = nil,
        detailText: String? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.status = status
        self.title = title
        self.subtitle = subtitle
        self.detailText = detailText
    }
}

extension StatusItem {
    enum Status {
        case verified
        case pending
        case unverified
        case info

        var symbolName: String {
            switch self {
            case .verified: return "checkmark"
            case .pending: return "ellipsis"
            case .unverified: return "xmark"
            case .info: return "info.circle"
            }
        }

        var tintColor: Color {
            switch self {
            case .verified: return .green
            case .pending: return .gray
            case .unverified: return .red
            case .info: return .blue
            }
        }
    }
}
