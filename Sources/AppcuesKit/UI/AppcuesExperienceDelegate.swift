//
//  AppcuesExperienceDelegate.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

public protocol AppcuesExperienceDelegate: AnyObject {
    func canDisplayExperience(experienceID: String) -> Bool
    func experienceWillAppear()
    func experienceDidAppear()
    func experienceWillDisappear()
    func experienceDidDisappear()
}

public extension AppcuesExperienceDelegate {
    /// Default implementation.
    func canDisplayExperience(experienceID: String) -> Bool {
        return true
    }

    /// Default implementation.
    func experienceWillAppear() {
        /* Default empty implementation */
    }

    /// Default implementation.
    func experienceDidAppear() {
        /* Default empty implementation */
    }

    /// Default implementation.
    func experienceWillDisappear() {
        /* Default empty implementation */
    }

    /// Default implementation.
    func experienceDidDisappear() {
        /* Default empty implementation */
    }
}
