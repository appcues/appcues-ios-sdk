//
//  AppcuesTargetElementTrait.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/17/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTargetElementTrait: AppcuesBackdropDecoratingTrait {
    struct Config: Decodable {
        let contentPreferredPosition: ContentPosition?
        let contentDistanceFromTarget: Double?
        let selector: [String: String]
    }

    static let type: String = "@appcues/target-element-beta"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let config: Config

    private lazy var frameObserverView = FrameObserverView()

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.config = config
    }

    func decorate(backdropView: UIView) throws {
        // Determine if the selector can be resolved to a view, failing the step if not.
        let targetRect = try calculateRect()
        // The first decorate call on the first step in a group will have a nil window because the views aren't added yet,
        // so skip setting a targetRectangle until we have proper bounds. The change handler below will take care of that.
        if backdropView.window != nil {
            metadataDelegate?.set([
                "contentPreferredPosition": config.contentPreferredPosition,
                "contentDistanceFromTarget": CGFloat(config.contentDistanceFromTarget ?? 0),
                "targetRectangle": targetRect
            ])
        }

        // Monitor the backdrop bounds to recalculate target-element position on changes.
        backdropView.insertSubview(frameObserverView, at: 0)
        frameObserverView.pin(to: backdropView)
        // Ensure the view bounds are updated *before* we add the frame observer block.
        frameObserverView.layoutIfNeeded()

        frameObserverView.onChange = { [weak self] _ in
            // this observer will ignore selector errors and use last known position on failure
            if let targetRectangle = try? self?.calculateRect() {
                self?.metadataDelegate?.set([
                    "contentPreferredPosition": self?.config.contentPreferredPosition,
                    "contentDistanceFromTarget": CGFloat(self?.config.contentDistanceFromTarget ?? 0),
                    "targetRectangle": targetRectangle
                ])
                // Force an update so that traits depending on this value will update.
                self?.metadataDelegate?.publish()
            }
        }
    }

    func undecorate(backdropView: UIView) throws {
        metadataDelegate?.unset(keys: [ "contentPreferredPosition", "contentDistanceFromTarget", "targetRectangle" ])

        frameObserverView.removeFromSuperview()
        frameObserverView.onChange = nil
    }

    private func calculateRect() throws -> CGRect {
        let view = try viewMatchingSelector()
        return CGRect(x: view.x, y: view.y, width: view.width, height: view.height)
    }

    private func viewMatchingSelector() throws -> AppcuesViewElement {

        let strategy = Appcues.elementTargeting

        guard let selector = strategy.inflateSelector(from: config.selector) else {
            throw AppcuesTraitError(description: "Invalid selector \(config.selector)")
        }

        guard let weightedViews = strategy.findMatches(for: selector) else {
            throw AppcuesTraitError(description: "Could not read application layout information")
        }

        // views contains an array of tuples, each item being the view and its integer
        // match value

        guard !weightedViews.isEmpty else {
            throw AppcuesTraitError(description: "No view matching selector \(config.selector)")
        }

        // if only a single match of anything, use it
        if weightedViews.count == 1 {
            return weightedViews[0].view
        }

        // iterating through the array, storing the highest weight value and the list of views
        // with that weight, resetting the list when we find a higher weight
        var maxWeight = -1
        var maxWeightViews: [AppcuesViewElement] = []

        weightedViews.forEach {
            let view = $0.view
            let weight = $0.weight
            if weight > maxWeight {
                // new max weight, reset list
                maxWeight = weight
                maxWeightViews = [view]
            } else if weight == maxWeight {
                // add to the list of current max weight views
                maxWeightViews.append(view)
            }
        }

        guard maxWeightViews.count == 1 else {
            // this selector was not able to find a distinct match in this view
            throw AppcuesTraitError(description: "multiple non-distinct views (\(weightedViews.count)) matched selector \(config.selector)")
        }

        // if this has produced a single most distinct result, use it
        return maxWeightViews[0]
    }
}
