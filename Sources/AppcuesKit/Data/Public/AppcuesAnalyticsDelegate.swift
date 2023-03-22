//
//  AppcuesAnalyticsDelegate.swift
//  AppcuesKit
//
//  Created by James Ellis on 6/27/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// The different types of analytics tracked by the SDK.
@objc
public enum AppcuesAnalytic: Int {
    /// A call to ``Appcues/track(name:properties:)`` or an internal SDK-generated event.
    case event
    /// A call to ``Appcues/screen(title:properties:)``.
    case screen
    /// A call to ``Appcues/identify(userID:properties:)``.
    case identify
    /// A call to ``Appcues/group(groupID:properties:)``.
    case group
}

/// Allows observation of analytics emitted by the SDK.
@objc
public protocol AppcuesAnalyticsDelegate: AnyObject {
    /// Notifies the delegate after Appcues analytics tracking occurs.
    /// - Parameters:
    ///   - analytic: The type of the analytic.
    ///   - value: Contains the primary value of the analytic being tracked. For events - the event name, for screens - the screen title,
    ///   for identify - the user ID, for group - the group ID.
    ///   - properties: Optional properties that provide additional context about the analytic.
    ///   - isInternal: True, if the analytic was internally generated by the SDK, as opposed to passed in from the host application,
    ///   for example, flow or session analytics.
    func didTrack(analytic: AppcuesAnalytic, value: String?, properties: [String: Any]?, isInternal: Bool)
}
