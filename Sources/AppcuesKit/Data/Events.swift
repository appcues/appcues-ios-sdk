//
//  Events.swift
//  AppcuesKit
//
//  Created by Matt on 2024-02-21.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation

internal enum Events {
    enum Session: String {
        case sessionStarted = "appcues:session_started"
    }

    enum Device: String {
        case deviceUpdated = "appcues:device_updated"
        case deviceUnregistered = "appcues:device_unregistered"
    }

    enum Push: String {
        case pushOpened = "appcues:push_opened"
    }

    enum Experience: String {
        case stepSeen = "appcues:v2:step_seen"
        case stepInteraction = "appcues:v2:step_interaction"
        case stepCompleted = "appcues:v2:step_completed"
        case stepError = "appcues:v2:step_error"
        case stepRecovered = "appcues:v2:step_recovered"
        case experienceStarted = "appcues:v2:experience_started"
        case experienceCompleted = "appcues:v2:experience_completed"
        case experienceDismissed = "appcues:v2:experience_dismissed"
        case experienceError = "appcues:v2:experience_error"
        case experienceRecovered = "appcues:v2:experience_recovered"
    }
}
