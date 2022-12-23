//
//  InteractionMonitor.swift
//
//
//  Created by Matt on 2022-06-08.
//

import UIKit

internal class InteractionMonitor {

    enum Mode {
        case disabled
        case cloning(String)
    }

    var mode: Mode = .disabled

    private let container: DIContainer

    private var _debugger: Any?
    @available(iOS 13.0, *)
    private var debugger: UIDebugging {
        if _debugger == nil {
            _debugger = container.resolve(UIDebugging.self)
        }
        // swiftlint:disable:next force_cast
        return _debugger as! UIDebugging
    }

    init(container: DIContainer) {
        self.container = container

        func swizzle(forClass: AnyClass, original: Selector, new: Selector) {
            guard let originalMethod = class_getInstanceMethod(forClass, original) else { return }
            guard let swizzledMethod = class_getInstanceMethod(forClass, new) else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        swizzle(forClass: UIApplication.self,
                original: #selector(UIApplication.sendEvent(_:)),
                new: #selector(UIApplication.appcues__sendEvent(_:))
        )

        container.resolve(Appcues.Config.self).logger.info("Interaction tracking enabled")

        NotificationCenter.appcues.addObserver(self, selector: #selector(interactionEventTracked), name: .appcuesInteractionEvent, object: nil)

        NotificationCenter.appcues.addObserver(self, selector: #selector(startClone), name: .appcuesTemplateClone, object: nil)

    }

    @objc
    private func interactionEventTracked(notification: Notification) {
        guard let view = notification.userInfo?["view"] as? UIView else { return }

        switch mode {
        case .disabled:
            break
        case .cloning(let type):
            if #available(iOS 13.0, *) {
                clone(view: view, of: type)
            }
            mode = .disabled
        }
    }

    @objc
    private func startClone(notification: Notification) {
        guard let type = notification.userInfo?["type"] as? String else { return }

        mode = .cloning(type)
    }

    @available(iOS 13.0, *)
    private func clone(view: UIView, of type: String) {
        if ["primaryButton", "secondaryButton"].contains(type), let button = view as? UIButton {
            debugger.clone(button, type: type)
            view.animateEmphasis()
        } else if ["headerText", "bodyText"].contains(type), let label = view as? UILabel {
            debugger.clone(label, type: type)
            view.animateEmphasis()
        } else if let superview = view.superview {
            // go up the hierarchy to see if we find what we're looking for
            clone(view: superview, of: type)
        }
    }
}

extension UIView{
     func animateEmphasis() {
         let originalAlpha = alpha
         let originalTransform = transform

         UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: [.curveEaseIn, .autoreverse],
            animations: {
                self.alpha = 0.8
                self.transform = self.transform.scaledBy(x: 1.2, y: 1.2)
            },
            completion: { _ in
                self.alpha = originalAlpha
                self.transform = originalTransform
            }
         )
     }
}


extension UIApplication {
    @objc
    internal func appcues__sendEvent(_ event: UIEvent) {
        // this is calling the original implementation of sendEvent since it has been swizzled
        appcues__sendEvent(event)

        guard event.allTouches?.count == 1, let touch = event.allTouches?.first, touch.phase == .ended, let view = touch.view else { return }

        NotificationCenter.appcues.post(
            name: .appcuesInteractionEvent,
            object: self,
            userInfo: [
                "view": view
            ]
        )
    }
}
