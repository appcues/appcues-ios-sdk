//
//  ExperienceContainerLifecycleHandler.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ExperienceContainerLifecycleHandler: AnyObject {
    func containerWillAppear()
    func containerDidAppear()
    func containerWillDisappear()
    func containerDidDisappear()

    /// NOTE: `pageIndex` refers to the index in the group, **not** the stepIndex in the experience.
    func containerNavigated(from oldPageIndex: Int, to newPageIndex: Int)
}
