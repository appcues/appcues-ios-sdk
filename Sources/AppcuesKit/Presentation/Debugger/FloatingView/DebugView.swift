//
//  DebugView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal protocol DebugViewDelegate: AnyObject {
    func debugView(did event: DebugView.Event)
}

@available(iOS 13.0, *)
// swiftlint:disable:next type_body_length attributes
internal class DebugView: UIView {

    private let gestureCalculator = GestureCalculator()

    weak var delegate: DebugViewDelegate?

    private let floatingViewPanRecognizer = UIPanGestureRecognizer()
    private let backgroundTapRecognizer = UITapGestureRecognizer()
    private let toastTapRecognizer = UITapGestureRecognizer()

    private var initialTouchOffsetFromCenter: CGPoint = .zero

    private var dismissViewTimer: Timer?
    private var canDismiss: Bool { dismissViewTimer?.isValid == false }
    private var isSnappedToDismissZone = false

    private var panelViewHideAnimator: UIViewPropertyAnimator?

    var fleetingLogView: FleetingLogView = {
        let view = FleetingLogView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    // Constraints to activate/deactivate depending on the floating view position
    private lazy var fleetingConstraints = (
        top: fleetingLogView.topAnchor.constraint(equalTo: floatingView.bottomAnchor),
        bottom: fleetingLogView.bottomAnchor.constraint(equalTo: floatingView.topAnchor),
        leading: fleetingLogView.leadingAnchor.constraint(equalTo: floatingView.leadingAnchor),
        trailing: fleetingLogView.trailingAnchor.constraint(equalTo: floatingView.trailingAnchor)
    )

    var floatingView = FloatingView(frame: CGRect(origin: .zero, size: CGSize(width: 64, height: 64)))

    private var dismissView: DismissDropZoneView = {
        let view = DismissDropZoneView()
        view.alpha = 0
        return view
    }()

    private var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.label.withAlphaComponent(0.3)
        view.alpha = 0
        return view
    }()

    var panelWrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0

        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8

        return view
    }()

    var toastView: CaptureToastView = {
        let view = CaptureToastView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0

        return view
    }()

    // MARK: Layout Calculators

    var baseFrame: CGRect = .zero

    private var relativeDockedPosition: CGPoint?
    var floatingViewDockedCenter: CGPoint {
        get {
            guard let relativeDockedPosition = relativeDockedPosition else {
                return floatingViewDefaultCenter
            }

            let newBoundingRect = floatingViewBoundingRect

            return CGPoint(
                x: relativeDockedPosition.x < 0.5 ? newBoundingRect.minX : newBoundingRect.maxX,
                y: newBoundingRect.height * relativeDockedPosition.y
            )
        }
        set {
            let boundingRect = floatingViewBoundingRect
            relativeDockedPosition = CGPoint(
                x: newValue.x / boundingRect.width,
                y: newValue.y / boundingRect.height
            )
        }
    }

    var floatingViewSize: CGSize { floatingView.frame.size }
    private let floatingViewEdgeInset: CGFloat = 0

    var floatingViewBoundingRect: CGRect {
        CGRect(origin: .zero, size: baseFrame.size).insetBy(
            dx: floatingViewSize.width / 2 - floatingViewEdgeInset,
            dy: floatingViewSize.height / 2 - floatingViewEdgeInset + 50
        )
    }

    var floatingViewOpenCenter: CGPoint {
        CGPoint(
            x: baseFrame.size.width * 0.5,
            y: 10 + safeAreaInsets.top + floatingViewSize.height / 2
        )
    }

    private var floatingViewDefaultCenter: CGPoint {
        CGPoint(
            x: baseFrame.size.width - floatingViewSize.width / 2 + floatingViewEdgeInset,
            y: baseFrame.size.height - 40 - safeAreaInsets.bottom - floatingViewSize.height / 2
        )
    }

    // MARK: Overrides

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backgroundView)
        addSubview(panelWrapperView)
        addSubview(dismissView)
        addSubview(floatingView)
        addSubview(toastView)

        backgroundView.pin(to: self)
        NSLayoutConstraint.activate([
            panelWrapperView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10 + floatingViewSize.height / 2),
            panelWrapperView.leadingAnchor.constraint(equalTo: leadingAnchor),
            panelWrapperView.trailingAnchor.constraint(equalTo: trailingAnchor),
            panelWrapperView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dismissView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dismissView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dismissView.bottomAnchor.constraint(equalTo: bottomAnchor),

            toastView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor, constant: 25),
            toastView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor, constant: -25),
            toastView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25),
            toastView.heightAnchor.constraint(equalToConstant: 64)

        ])

        floatingViewPanRecognizer.addTarget(self, action: #selector(floatingViewPanned))
        floatingView.addGestureRecognizer(floatingViewPanRecognizer)

        backgroundTapRecognizer.addTarget(self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(backgroundTapRecognizer)

        toastTapRecognizer.addTarget(self, action: #selector(toastTapped))
        toastView.addGestureRecognizer(toastTapRecognizer)

        // Set initial position and then animate in
        setFloatingView(visible: false, animated: false, programmatically: true)
        setFloatingView(visible: true, animated: true, programmatically: true)

        addSubview(fleetingLogView)
        NSLayoutConstraint.activate([
            fleetingLogView.widthAnchor.constraint(equalToConstant: 150),
            fleetingLogView.heightAnchor.constraint(equalToConstant: 150)
            // Additional constraints are set depending on orientation
        ])
        updateFleetingLogViewOrientation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update floatingView position on frame changes
        if baseFrame != frame {
            baseFrame = frame
            floatingView.center = panelWrapperView.alpha > 0 ? floatingViewOpenCenter : floatingViewDockedCenter
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        var hitView: UIView?
        var didTapToast = false

        for view in subviews.reversed() {
            // Convert to the subview's local coordinate system
            let convertedPoint = convert(point, to: view)
            if !view.point(inside: convertedPoint, with: event) {
                // Not inside the subview, keep looking
                continue
            }

            // If the subview can find a hit target, return that
            if let target = view.hitTest(convertedPoint, with: event) {
                hitView = target
                didTapToast = view == toastView
                break
            }
        }

        // any tap outside the toast when it is visible should hide toast
        // taps inside the toast are handled within the toast
        if toastView.alpha > 0 && !didTapToast {
            animateToast(visible: false, animated: true, completion: nil)
        }

        return hitView
    }

    // MARK: API

    func setFloatingView(visible isVisible: Bool, animated: Bool, programmatically: Bool, notify: Bool = true) {
        floatingView.animateVisibility(visible: isVisible, animated: animated, haptics: !programmatically) {
            if notify {
                self.delegate?.debugView(did: isVisible ? .show : .hide)
            }
        }
    }

    func setPanelInterface(open isOpen: Bool, animated: Bool, programatically: Bool) {
        let center = isOpen ? floatingViewOpenCenter : floatingViewDockedCenter
        floatingView.animatePosition(to: center, animated: animated, haptics: !programatically)
        animatePanel(visible: isOpen, animated: animated, haptics: !programatically)
        delegate?.debugView(did: isOpen ? .open : .close)

        fleetingLogView.isLocked = isOpen
    }

    func setToastView(visible isVisible: Bool, animated: Bool, completion: (() -> Void)?) {
        animateToast(visible: isVisible, animated: animated, completion: completion)
    }

    // MARK: Gesture Recognizers

    @objc
    private func floatingViewPanned(recognizer: UIPanGestureRecognizer) {
        let shouldDock = handlePanWhileOpen(recognizer)

        // If the floating view is snapped to the dismiss zone, no need to proceed
        let shouldDismiss: Bool = handlePanToDismiss(recognizer)
        guard !shouldDismiss else { return }

        switch recognizer.state {
        case .began:
            panBegan(recognizer)
        case .changed:
            panChanged(recognizer)
        case .ended, .cancelled:
            panEnded(recognizer, shouldDock: shouldDock)
        default:
            break
        }
    }

    @objc
    private func backgroundTapped(recognizer: UITapGestureRecognizer) {
        setPanelInterface(open: false, animated: true, programatically: true)
    }

    @objc
    private func toastTapped(recognizer: UITapGestureRecognizer) {
        setToastView(visible: false, animated: true, completion: nil)
    }

    // MARK: Pan Gesture

    private func panBegan(_ recognizer: UIPanGestureRecognizer) {
        let touchPoint = recognizer.location(in: self)

        initialTouchOffsetFromCenter = CGPoint(
            x: touchPoint.x - floatingView.center.x,
            y: touchPoint.y - floatingView.center.y
        )

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        fleetingLogView.clear()
    }

    private func panChanged(_ recognizer: UIPanGestureRecognizer) {
        let touchPoint = recognizer.location(in: self)

        floatingView.center = CGPoint(
            x: touchPoint.x - initialTouchOffsetFromCenter.x,
            y: touchPoint.y - initialTouchOffsetFromCenter.y
        )
    }

    private func panEnded(_ recognizer: UIPanGestureRecognizer, shouldDock: Bool) {
        let velocity = recognizer.velocity(in: self)
        let projectedPosition = CGPoint(
            x: floatingView.center.x + gestureCalculator.project(initialVelocity: velocity.x),
            y: floatingView.center.y + gestureCalculator.project(initialVelocity: velocity.y)
        )

        let destinationPoint: CGPoint
        let damping: CGFloat

        if shouldDock {
            destinationPoint = gestureCalculator.restingPoint(
                from: floatingView.center,
                to: projectedPosition,
                within: floatingViewBoundingRect
            )
            damping = gestureCalculator.dynamicDamping(magnitude: destinationPoint.distance(from: projectedPosition))
        } else {
            // Snap back to open state & position
            destinationPoint = floatingViewOpenCenter
            damping = 0.6
        }

        let relativeInitialVelocity = CGVector(
            dx: gestureCalculator.relativeVelocity(forVelocity: velocity.x, from: floatingView.center.x, to: destinationPoint.x),
            dy: gestureCalculator.relativeVelocity(forVelocity: velocity.y, from: floatingView.center.y, to: destinationPoint.y)
        )

        let timing = UISpringTimingParameters(
            damping: damping,
            response: 0.4,
            initialVelocity: relativeInitialVelocity
        )
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)
        animator.addAnimations {
            self.floatingViewDockedCenter = destinationPoint
            self.floatingView.center = destinationPoint
            if shouldDock {
                self.updateFleetingLogViewOrientation()
                self.delegate?.debugView(did: .reposition)
            }
        }
        animator.startAnimation()
    }

    private func handlePanWhileOpen(_ recognizer: UIPanGestureRecognizer) -> Bool {
        // `panelWrapperView.alpha > 0` for the began case, `panelViewHideAnimator != nil` for the others.
        guard self.panelWrapperView.alpha > 0 || panelViewHideAnimator != nil else { return true }

        switch recognizer.state {
        case .began:
            let animator = UIViewPropertyAnimator(duration: 0, curve: .linear, animations: {
                self.panelWrapperView.alpha = 0
                self.backgroundView.alpha = 0
            })
            animator.startAnimation()
            animator.pauseAnimation()
            panelViewHideAnimator = animator
        case .changed:
            panelViewHideAnimator?.fractionComplete = recognizer.translation(in: self).distance(from: CGPoint.zero) / 50
        case .ended:
            panelViewHideAnimator?.stopAnimation(true)
            panelViewHideAnimator?.finishAnimation(at: .start)
            panelViewHideAnimator = nil

            if recognizer.translation(in: self).distance(from: CGPoint.zero) < 50 {
                // reset the panel view back to its open state
                UIView.animate(
                    withDuration: 0.2,
                    animations: {
                        self.panelWrapperView.alpha = 1
                        self.backgroundView.alpha = 1
                    },
                    completion: nil
                )
                return false
            }
        default:
            break
        }

        return true
    }

    private func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) -> Bool {
        let distanceFromSnapPoint = recognizer.location(in: self).distance(from: dismissView.snapPoint)
        let isInDismissRange: Bool = canDismiss && distanceFromSnapPoint < dismissView.snapRange

        switch recognizer.state {
        case .began:
            dismissViewTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                self.dismissView.animateVisibility(visible: true, animated: true)
            }
        case .changed:
            if isInDismissRange {
                // Only snap once while we're in the dismiss range
                if !isSnappedToDismissZone {
                    floatingView.animateSnap(to: dismissView.snapPoint)
                }
            } else {
                if isSnappedToDismissZone {
                    // Unsnap
                    let touchPoint = recognizer.location(in: self)
                    let centerPoint = CGPoint(
                        x: touchPoint.x - initialTouchOffsetFromCenter.x,
                        y: touchPoint.y - initialTouchOffsetFromCenter.y
                    )
                    floatingView.animateSnap(to: centerPoint)
                }
            }

            isSnappedToDismissZone = isInDismissRange
        case .ended:
            dismissViewTimer?.invalidate()
            dismissViewTimer = nil

            dismissView.animateVisibility(visible: false, animated: true)

            if isSnappedToDismissZone {
                setFloatingView(visible: false, animated: true, programmatically: false)
            }
        default:
            break
        }

        return isInDismissRange
    }

    // MARK: Fleeting Log View

    private func updateFleetingLogViewOrientation() {
        if floatingView.center.x < center.x {
            fleetingLogView.orientation.x = .leading
            fleetingConstraints.leading.isActive = true
            fleetingConstraints.trailing.isActive = false
        } else {
            fleetingLogView.orientation.x = .trailing
            fleetingConstraints.leading.isActive = false
            fleetingConstraints.trailing.isActive = true
        }

        if floatingView.center.y < center.y {
            fleetingLogView.orientation.y = .bottom
            fleetingConstraints.top.isActive = true
            fleetingConstraints.bottom.isActive = false
        } else {
            fleetingLogView.orientation.y = .top
            fleetingConstraints.top.isActive = false
            fleetingConstraints.bottom.isActive = true
        }
    }

    // MARK: Animations

    private func animatePanel(visible isVisible: Bool, animated: Bool, haptics: Bool) {

        let animations: () -> Void = {
            self.panelWrapperView.alpha = isVisible ? 1 : 0
            self.backgroundView.alpha = isVisible ? 1 : 0
        }

        let completion: (Bool) -> Void = { _ in
            // Capture/reset accessibility focus to the debug panel.
            self.window?.accessibilityViewIsModal = isVisible
        }

        if animated {
            UIView.animate(
                withDuration: 0.6,
                animations: animations,
                completion: completion
            )
        } else {
            animations()
            completion(true)
        }
    }

    private func animateToast(visible isVisible: Bool, animated: Bool, completion: (() -> Void)?) {

        let animations: () -> Void = {
            self.toastView.alpha = isVisible ? 1 : 0
        }

        if animated {
            UIView.animate(
                withDuration: 0.6,
                animations: animations
            ) { _ in completion?() }
        } else {
            animations()
            completion?()
        }
    }

}

@available(iOS 13.0, *)
extension DebugView {
    enum Event {
        case show
        case hide
        case open
        case close
        case reposition
        case screenCapture(Authorization)
    }
}
