//
//  AppcuesTargetElementTrait.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/17/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTargetElementTrait: BackdropDecoratingTrait {
    struct Config: Decodable {
        let selector: ElementSelector
    }

    private class FrameObserverView: UIView {
        private var oldBounds: CGRect = .zero
        var onChange: (() -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()
            if oldBounds != bounds {
                onChange?()
            }
            oldBounds = bounds
        }
    }

    static let type: String = "@appcues/target-element"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let config: Config

    private lazy var frameObserverView = FrameObserverView()

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.config = config
    }

    func decorate(backdropView: UIView) throws {
        // Determine if the selector can be resolved to a view, failing the step if not.
        let targetRect = try calculateRect()
        // The first decorate call on the first step in a group will have a nil window because the views aren't added yet,
        // so skip setting a targetRectangle until we have proper bounds. The change handler below will take care of that.
        if backdropView.window != nil {
            metadataDelegate?.set([ "targetRectangle": targetRect ])
        }

        // Monitor the backdrop bounds to recalculate target-element position on changes.
        backdropView.insertSubview(frameObserverView, at: 0)
        frameObserverView.pin(to: backdropView)
        // Ensure the view bounds are updated *before* we add the frame observer block.
        frameObserverView.layoutIfNeeded()

        frameObserverView.onChange = { [weak self] in
            // this observer will ignore selector errors and use last known position on failure
            if let targetRectangle = try? self?.calculateRect() {
                self?.metadataDelegate?.set([ "targetRectangle": targetRectangle ])
                // Force an update so that traits depending on this value will update.
                self?.metadataDelegate?.publish()
            }
        }
    }

    func undecorate(backdropView: UIView) throws {
        metadataDelegate?.unset(keys: [ "targetRectangle" ])

        frameObserverView.removeFromSuperview()
        frameObserverView.onChange = nil
    }

    private func calculateRect() throws -> CGRect {
        guard let window = UIApplication.shared.windows.first(where: { !($0 is DebugUIWindow) }) else {
            throw TraitError(description: "No active window found")
        }

        let view = try window.viewMatchingSelector(config.selector)
        return view.convert(view.bounds, to: nil)
    }
}

private extension UIView {

    func viewMatchingSelector(_ target: ElementSelector) throws -> UIView {
        let views = viewsMatchingSelector(target)

        guard !views.isEmpty else {
            throw TraitError(description: "No view matching selector \(target)")
        }

        // if only a single match of anything, use it
        if views.count == 1 {
            return views[0]
        }

        // weight the selector property matches by how distinct they are considered
        let weightedMatches = views.map { view -> (UIView, Int) in
            var weight = 0

            if view.isMatch(for: target, on: \.accessibilityIdentifier) {
                weight += 10_000
            }

            if view.isMatch(for: target, on: \.tag) {
                weight += 1_000
            }

            if view.isMatch(for: target, on: \.description) {
                weight += 100
            }

            return (view, weight)
        }

        // find the maximum weight value from all matches
        if let maxWeight = weightedMatches.max(by: { $0.1 > $1.1 })?.1 {
            // find the items with this weight
            let maxItems = weightedMatches.filter { $0.1 == maxWeight }
            // if this has produced a single most distinct result, use it
            if maxItems.count == 1 {
                return maxItems[0].0
            }
        }

        // otherwise, this selector was not able to find a distinct match in this view
        throw TraitError(description: "multiple non-distinct views (\(views.count)) matched selector \(target)")
    }

    func viewsMatchingSelector(_ target: ElementSelector) -> [UIView] {
        var views: [UIView] = []

        if let current = self.appcuesSelector {
            if (target.accessibilityIdentifier != nil && target.accessibilityIdentifier == current.accessibilityIdentifier) ||
                (target.tag != nil && target.tag == current.tag) ||
                (target.description != nil && target.description == current.description) {
                views.append(self)
            }
        }

        for subview in self.subviews {
            views.append(contentsOf: subview.viewsMatchingSelector(target))
        }

        return views
    }

    func isMatch(for targetSelector: ElementSelector, on keyPath: KeyPath<ElementSelector, String?>) -> Bool {
        guard let targetValue = targetSelector[keyPath: keyPath],
              let selector = self.appcuesSelector else {
            return false
        }
        return selector[keyPath: keyPath] == targetValue
    }
}
