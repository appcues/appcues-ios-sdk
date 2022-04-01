//
//  AnalyticsSubscribing.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol AnalyticsSubscribing: AnyObject {
    func track(update: TrackingUpdate)
}
