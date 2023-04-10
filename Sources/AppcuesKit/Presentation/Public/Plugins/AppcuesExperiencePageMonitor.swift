//
//  AppcuesExperiencePageMonitor.swift
//  AppcuesKit
//
//  Created by Matt on 2022-02-03.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// Maintains page state metadata for an ``AppcuesExperienceContainerViewController``.
@objc
public class AppcuesExperiencePageMonitor: NSObject {

    // Using closures as observers is ok from a memory management perspective because the lifecycle of any Trait
    // observing the experience controller and the experience controller itself should be the same.
    private var observers: [(Int, Int) -> Void] = []

    /// The number of pages in the ``AppcuesExperienceContainerViewController``.
    @objc public let numberOfPages: Int

    /// The current page in the ``AppcuesExperienceContainerViewController``.
    @objc public private(set) var currentPage: Int

    /// Creates an instance of a page monitor.
    /// - Parameters:
    ///   - numberOfPages: The total number of pages
    ///   - currentPage: The initial page
    @objc
    public init(numberOfPages: Int, currentPage: Int) {
        self.numberOfPages = numberOfPages
        self.currentPage = currentPage
        super.init()
    }

    /// Adds the specified closure to the list of closures to invoke when the ``currentPage`` value changes.
    /// - Parameter closure: The closure to invoke.
    @objc
    public func addObserver(closure: @escaping (_ currentIndex: Int, _ oldIndex: Int) -> Void) {
        observers.append(closure)
    }

    /// Update the ``currentPage`` value and notify all observers of the change.
    /// - Parameter currentPage: Page index
    ///
    /// Setting a value equal to the current state will not notify observers.
    @objc
    public func set(currentPage: Int) {
        let previousPage = self.currentPage
        guard currentPage != previousPage else { return }
        self.currentPage = currentPage

        observers.forEach { closure in
            closure(currentPage, previousPage)
        }
    }
}
