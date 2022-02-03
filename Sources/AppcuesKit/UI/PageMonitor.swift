//
//  PageMonitor.swift
//  AppcuesKit
//
//  Created by Matt on 2022-02-03.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

public class PageMonitor {
    // Using closures as observers is ok from a memory management perspective because the lifecycle of any Trait
    // observing the experience controller and the experience controller itself should be the same.
    private var observers: [(Int, Int) -> Void] = []

    let numberOfPages: Int
    private(set) var currentPage: Int

    init(numberOfPages: Int, currentPage: Int) {
        self.numberOfPages = numberOfPages
        self.currentPage = currentPage
    }

    func addObserver(closure: @escaping (Int, Int) -> Void) {
        observers.append(closure)
    }

    func set(currentPage: Int) {
        let previousPage = self.currentPage
        guard currentPage != previousPage else { return }
        self.currentPage = currentPage

        observers.forEach { closure in
            closure(currentPage, previousPage)
        }
    }
}
