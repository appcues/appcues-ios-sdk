// The MIT License (MIT)
//
// Copyright (c) 2014-2016 Flipboard
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Derived from: https://github.com/Flipboard/FLAnimatedImage/blob/master/FLAnimatedImage/FLAnimatedImageView.m

import UIKit

// swiftlint:disable all

internal protocol FLAnimatedImageViewDebugDelegate: AnyObject {
    func animatedImageView(_ animatedImageView: FLAnimatedImageView, waitingForFrame index: Int, withDuration duration: TimeInterval)
}

///  An `FLAnimatedImageView` can take an `FLAnimatedImage` and plays it automatically when in view hierarchy and stops when removed.
///  The animation can also be controlled with the `UIImageView` methods `-start/stop/isAnimating`.
///  It is a fully compatible `UIImageView` subclass and can be used as a drop-in component to work with existing code paths expecting to display a `UIImage`.
///  Under the hood it uses a `CADisplayLink` for playback, which can be inspected with `currentFrame` & `currentFrameIndex`.
internal class FLAnimatedImageView: UIImageView {

    var animatedImage: FLAnimatedImage? {
        didSet {
            guard animatedImage != oldValue else { return }
            animatedImageDidSet(animatedImage: animatedImage)
        }
    }

    var currentFrame: UIImage?
    var currentFrameIndex: Int = 0

    var loopCountdown: Int = .max
    var loopCompletionBlock: ((Int) -> Void)?

    private var accumulator: TimeInterval = 0
    private lazy var displayLink: CADisplayLink = {
        // It is important to note the use of a weak proxy here to avoid a retain cycle. `-displayLinkWithTarget:selector:`
        // will retain its target until it is invalidated. We use a weak proxy so that the image view will get deallocated
        // independent of the display link's lifetime. Upon image view deallocation, we invalidate the display
        // link which will lead to the deallocation of both the display link and the weak proxy.

        let proxy = DisplayLinkProxy(self)
        let displayLink = CADisplayLink(target: proxy, selector: #selector(proxy.displayDidRefresh(displayLink:)))

        displayLink.add(to: .main, forMode: .common)
        return displayLink
    }()

    /// Before checking this value, call `-updateShouldAnimate` whenever the animated image, window or superview has changed.
    var shouldAnimate = false
    var needsDisplayWhenImageBecomesAvailable = false

    // MARK: Auto Layout

    override var intrinsicContentSize: CGSize {
        // Default to let UIImageView handle the sizing of its image, and anything else it might consider.
        // If we have have an animated image, use its image size.
        // UIImageView's intrinsic content size seems to be the size of its image. The obvious approach, simply calling `-invalidateIntrinsicContentSize` when setting an animated image, results in UIImageView steadfastly returning `{UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric}` for its intrinsicContentSize.
        // (Perhaps UIImageView bypasses its `-image` getter in its implementation of `-intrinsicContentSize`, as `-image` is not called after calling `-invalidateIntrinsicContentSize`.)

        if animatedImage != nil, let size = image?.size {
            return size
        } else {
            return super.intrinsicContentSize
        }
    }

    // MARK: Image Data

    override var image: UIImage? {
        get {
            if animatedImage != nil {
                return currentFrame
            } else {
                return super.image
            }
        } set {
            if image != nil {
                // Clear out the animated image and implicitly pause animation playback.
                animatedImage = nil
            }

            super.image = newValue
        }
    }

    override var isAnimating: Bool {
        if animatedImage != nil {
            return !displayLink.isPaused
        } else {
            return super.isAnimating
        }
    }

    // MARK: Highlight Image Unsupport

    override var isHighlighted: Bool {
        didSet {
            // Highlighted image is unsupported for animated images, but implementing it breaks the image view when embedded in a UICollectionViewCell.
            if animatedImage == nil {
                super.isHighlighted = false
            }
        }
    }

    override var alpha: CGFloat {
        didSet {
            updateShouldAnimate()
            if shouldAnimate {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }

    override var isHidden: Bool {
        didSet {
            updateShouldAnimate()
            if shouldAnimate {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }

    // Only intended to report internal state for debugging
    weak var debugDelegate: FLAnimatedImageViewDebugDelegate?

    // MARK: - Life Cycle

    init() {
        super.init(image: nil)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    init(animatedImage: FLAnimatedImage?) {
        self.animatedImage = animatedImage
        super.init(image: nil)
        animatedImageDidSet(animatedImage: self.animatedImage)
    }

    // MARK: - UIView Method Overrides

    // MARK: Observing View-Related Changes

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        updateShouldAnimate()
        if shouldAnimate {
            startAnimating()
        } else {
            stopAnimating()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        updateShouldAnimate()
        if shouldAnimate {
            startAnimating()
        } else {
            stopAnimating()
        }
    }

    // MARK: - UIImageView Method Overrides

    override func startAnimating() {
        if animatedImage != nil {
            // Adjusting preferredFramesPerSecond allows us to skip unnecessary calls to displayDidRefresh: when showing GIFs
            // that don't animate quickly. Use ceil to err on the side of too many FPS so we don't miss a frame transition moment.
            displayLink.preferredFramesPerSecond = Int(ceil(1.0 / frameDelayGreatestCommonDivisor()))
            displayLink.isPaused = false
        } else {
            super.startAnimating()

        }
    }

    override func stopAnimating() {
        if animatedImage != nil {
            displayLink.isPaused = true
        } else {
            super.stopAnimating()
        }
    }

    // MARK: - CALayerDelegate (Informal)
    // MARK: Providing the Layer's Content

    override func display(_ layer: CALayer) {
        layer.contents = image?.cgImage
    }

    // MARK: - Private Methods

    private func animatedImageDidSet(animatedImage: FLAnimatedImage?) {
        if let animatedImage = animatedImage {
            if super.image != nil {
                // UIImageView's `setImage:` will internally call its layer's `setContentsTransform:` based on the `image.imageOrientation`.
                // The `contentsTransform` will affect layer rendering rotation because the CGImage's bitmap buffer does not actually take rotation.
                // However, when calling `setImage:nil`, this `contentsTransform` will not be reset to identity.
                // Further animation frame will be rendered as rotated. So we must set it to the poster image to clear the previous state.
                // See more here: https://github.com/Flipboard/FLAnimatedImage/issues/100
                super.image = animatedImage.posterImage
                // Clear out the image.
                super.image = nil
            }

            // Ensure disabled highlighting; it's not supported (see `-setHighlighted:`).
            super.isHighlighted = false
            // UIImageView seems to bypass some accessors when calculating its intrinsic content size, so this ensures its intrinsic content size comes from the animated image.
            invalidateIntrinsicContentSize()

            currentFrame = animatedImage.posterImage
            currentFrameIndex = 0
            if animatedImage.loopCount > 0 {
                loopCountdown = animatedImage.loopCount
            } else {
                loopCountdown = .max
            }
        } else {
            // Stop animating before the animated image gets cleared out.
            stopAnimating()
            // Clear out the image.
            super.image = nil
            currentFrame = nil
        }

        accumulator = 0

        // Start animating after the new animated image has been set.
        updateShouldAnimate()
        if shouldAnimate {
            startAnimating()
        }

        layer.setNeedsDisplay()
    }

    // MARK: Animating Images

    private func frameDelayGreatestCommonDivisor() -> TimeInterval {
        guard let delays = animatedImage?.delayTimesForIndexes.map({ $1 }), let first = delays.first else { return FLAnimatedImage.Constants.gcdPrecision }

        // Scales the frame delays by `kGreatestCommonDivisorPrecision`
        // then converts it to an UInteger for in order to calculate the GCD.
        var scaledGCD: Int = lrint(first * FLAnimatedImage.Constants.gcdPrecision)
        delays.forEach {
            scaledGCD = gcd(lrint($0 * FLAnimatedImage.Constants.gcdPrecision), scaledGCD)
        }

        // Reverse to scale to get the value back into seconds.
        return Double(scaledGCD) / FLAnimatedImage.Constants.gcdPrecision
    }

    // swiftlint:disable identifier_name
    private func gcd(_ a: Int, _ b: Int) -> Int {
        // http://en.wikipedia.org/wiki/Greatest_common_divisor
        if a < b {
            return gcd(b, a)
        } else if a == b {
            return b
        }

        var a = a
        var b = b
        while true {
            let remainder = a % b
            if remainder == 0 {
                return b
            }
            a = b
            b = remainder
        }
    }
    // swiftlint:enable identifier_name

    // MARK: Animation

    /// Don't repeatedly check our window & superview in `-displayDidRefresh:` for performance reasons.
    /// Just update our cached value whenever the animated image, window or superview is changed.
    private func updateShouldAnimate() {
        shouldAnimate = animatedImage != nil && window != nil && superview != nil
    }

    func displayDidRefresh(displayLink: CADisplayLink) {
        // If for some reason a wild call makes it through when we shouldn't be animating, bail.
        // Early return!
        guard shouldAnimate, let animatedImage = animatedImage else {
            FLAnimatedImage.log(.warn, "Trying to animate image when we shouldn't")
            return
        }

        // If we don't have a frame delay (e.g. corrupt frame), don't update the view but skip the playhead to the next frame (in else-block).
        if let delayTime = animatedImage.delayTimesForIndexes[currentFrameIndex] {
            if let image = animatedImage.imageLazilyCachedAt(index: currentFrameIndex) {
                FLAnimatedImage.log(.verbose, "Showing frame \(currentFrameIndex) for animated image: \(animatedImage)")
                currentFrame = image

                if needsDisplayWhenImageBecomesAvailable {
                    layer.setNeedsDisplay()
                    needsDisplayWhenImageBecomesAvailable = false
                }

                accumulator += displayLink.targetTimestamp - CACurrentMediaTime()

                // While-loop first inspired by & good Karma to: https://github.com/ondalabs/OLImageView/blob/master/OLImageView.m
                while accumulator >= delayTime {
                    accumulator -= delayTime
                    currentFrameIndex += 1
                    if currentFrameIndex >= animatedImage.frameCount {
                        // If we've looped the number of times that this animated image describes, stop looping.
                        loopCountdown -= 1
                        loopCompletionBlock?(loopCountdown)

                        if loopCountdown == 0 {
                            stopAnimating()
                            return
                        }

                        currentFrameIndex = 0
                    }

                    // Calling `-setNeedsDisplay` will just paint the current frame, not the new frame that we may have moved to.
                    // Instead, set `needsDisplayWhenImageBecomesAvailable` to `true` -- this will paint the new image once loaded.
                    needsDisplayWhenImageBecomesAvailable = true
                }
            } else {
                FLAnimatedImage.log(.debug, "Waiting for frame \(currentFrameIndex) for animated image: \(self)")
                debugDelegate?.animatedImageView(
                    self,
                    waitingForFrame: currentFrameIndex,
                    withDuration: displayLink.targetTimestamp - CACurrentMediaTime())
            }
        } else {
            currentFrameIndex += 1
        }
    }

    deinit {
        displayLink.invalidate()
    }
}

private extension FLAnimatedImageView {

    /// Prevents the retain cycle caused by CADisplayLink
    private class DisplayLinkProxy {
        weak var view: FLAnimatedImageView?

        init(_ view: FLAnimatedImageView) {
            self.view = view
        }

        @objc
        func displayDidRefresh(displayLink: CADisplayLink) {
            view?.displayDidRefresh(displayLink: displayLink)
        }
    }
}
