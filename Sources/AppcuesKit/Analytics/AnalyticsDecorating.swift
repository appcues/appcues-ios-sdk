//
//  AnalyticsDecorating.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/1/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsDecorating: AnyObject {
    func decorate(_ tracking: TrackingUpdate) -> TrackingUpdate
}
