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

        // TODO: Convert `Color` to `UIColor` pre-iOS 14?
        if #available(iOS 14.0, *) {
            if let currentTintColor = context.environment.currentPageIndicatorTintColor {
                uiView.currentPageIndicatorTintColor = UIColor(currentTintColor)
            }
            if let pageTintColor = context.environment.pageIndicatorTintColor {
                uiView.pageIndicatorTintColor = UIColor(pageTintColor)
            }
        }
    }
}

extension PageControl {
    struct TintColorEnvironmentKey: EnvironmentKey {
        static let defaultValue: Color? = nil
    }

    struct CurrentTintColorEnvironmentKey: EnvironmentKey {
        static let defaultValue: Color? = nil
    }
}

extension EnvironmentValues {
    var pageIndicatorTintColor: Color? {
        get {
            self[PageControl.TintColorEnvironmentKey.self]
        } set {
            self[PageControl.TintColorEnvironmentKey.self] = newValue
        }
    }

    var currentPageIndicatorTintColor: Color? {
        get {
            self[PageControl.CurrentTintColorEnvironmentKey.self]
        } set {
            self[PageControl.CurrentTintColorEnvironmentKey.self] = newValue
        }
    }
}

extension View {
    func pageIndicatorTintColor(_ color: Color?) -> some View {
        environment(\.pageIndicatorTintColor, color)
    }

    func currentPageIndicatorTintColor(_ color: Color?) -> some View {
        environment(\.currentPageIndicatorTintColor, color)
    }
}
