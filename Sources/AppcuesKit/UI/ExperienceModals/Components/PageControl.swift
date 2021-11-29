//
//  PageControl.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI
import UIKit

internal struct PageControl {
    var numberOfPages: Int
    @Binding var currentPage: Int
}

extension PageControl: UIViewRepresentable {

    class Coordinator: NSObject {
        var control: PageControl

        init(_ control: PageControl) {
            self.control = control
        }

        @objc
        func updateCurrentPage(sender: UIPageControl) {
            control.currentPage = sender.currentPage
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.hidesForSinglePage = true
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateCurrentPage(sender:)),
            for: .valueChanged)

        return control
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = numberOfPages
        uiView.currentPage = currentPage

        if let currentTintColor = context.environment.currentPageIndicatorTintColor {
            uiView.currentPageIndicatorTintColor = currentTintColor
        }
        if let pageTintColor = context.environment.pageIndicatorTintColor {
            uiView.pageIndicatorTintColor = pageTintColor
        }
    }
}

// NOTE: Using UIColor here instead of Color since iOS 13 has no nice way to convert a Color back to UIColor for the UIKit.UIPageControl.

extension PageControl {
    struct TintColorEnvironmentKey: EnvironmentKey {
        static let defaultValue: UIColor? = nil
    }

    struct CurrentTintColorEnvironmentKey: EnvironmentKey {
        static let defaultValue: UIColor? = nil
    }
}

extension EnvironmentValues {
    var pageIndicatorTintColor: UIColor? {
        get {
            self[PageControl.TintColorEnvironmentKey.self]
        } set {
            self[PageControl.TintColorEnvironmentKey.self] = newValue
        }
    }

    var currentPageIndicatorTintColor: UIColor? {
        get {
            self[PageControl.CurrentTintColorEnvironmentKey.self]
        } set {
            self[PageControl.CurrentTintColorEnvironmentKey.self] = newValue
        }
    }
}

extension View {
    func pageIndicatorTintColor(_ color: UIColor?) -> some View {
        environment(\.pageIndicatorTintColor, color)
    }

    func currentPageIndicatorTintColor(_ color: UIColor?) -> some View {
        environment(\.currentPageIndicatorTintColor, color)
    }
}
