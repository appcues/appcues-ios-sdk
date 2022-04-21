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

// Derived from: https://github.com/Flipboard/FLAnimatedImage/blob/master/FLAnimatedImage/FLAnimatedImage.m

import UIKit
import MobileCoreServices

// swiftlint:disable all

internal protocol FLAnimatedImageDebugDelegate: AnyObject {
    func animatedImage(_ animatedImage: FLAnimatedImage, didUpdateCachedFrames indexesOfFramesInCache: IndexSet)
    func animatedImage(_ animatedImage: FLAnimatedImage, didRequestCachedFrame index: Int)
    func animatedImagePredrawingSlowdownFactor(for animatedImage: FLAnimatedImage) -> CGFloat
}

internal class FLAnimatedImage: NSObject {

    enum Constants {
        static let frameDefaultDelay: TimeInterval = 0.1
        /// This is how the fastest browsers do it as per 2012: http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility
        static let frameMinimumDelay: TimeInterval = 0.02

        static let cacheResetDelay: TimeInterval = 3.0
        static let cacheGrowDelay: TimeInterval = 2.0
        static let cacheGrowAttemptsMax: Int = 2

        /// Precision is set to half of the `frameMinimumDelay` in order to minimize frame dropping.
        static let gcdPrecision: TimeInterval = 2.0 / FLAnimatedImage.Constants.frameMinimumDelay
    }

    /// For custom dispatching of memory warnings to avoid deallocation races since NSNotificationCenter doesn't retain objects it is notifying.
    private static let allAnimatedImagesWeak: NSHashTable<FLAnimatedImage> = {
        let hashTable = NSHashTable<FLAnimatedImage>(options: NSHashTableWeakMemory)

        NotificationCenter.default
            .addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil) { note in
                // UIKit notifications are posted on the main thread. didReceiveMemoryWarning: is expecting the main run loop, and we don't lock on allAnimatedImagesWeak
                assert(Thread.isMainThread, "Received memory warning on non-main thread")
                // Get a strong reference to all of the images. If an instance is returned in this array, it is still live and has not entered dealloc.
                // Note that FLAnimatedImages can be created on any thread, so the hash table must be locked.
                var images: [FLAnimatedImage] = []

                objc_sync_enter(allAnimatedImagesWeak)
                images = allAnimatedImagesWeak.allObjects
                objc_sync_exit(allAnimatedImagesWeak)
                // Now issue notifications to all of the images while holding a strong reference to them
                images.forEach {
                    $0.perform(#selector(didReceiveMemoryWarning), with: note)
                }
            }

        return hashTable
    }()

    /// The data the receiver was initialized with
    let data: Data

    /// Enables predrawing of images to improve performance.
    private var isPredrawingEnabled: Bool

    private let imageSource: CGImageSource

    /// Guaranteed to be loaded; usually equivalent to `-imageLazilyCachedAtIndex:0`
    let posterImage: UIImage

    /// Index of non-purgable poster image
    private let posterImageFrameIndex: Int

    /// The `.posterImage`'s `.size`
    let size: CGSize

    /// "The number of times to repeat an animated sequence." according to ImageIO (note the slightly different definition to Netscape 2.0 Loop Extension); 0 means repeating the animation forever
    let loopCount: Int

    /// Of type `TimeInterval` boxed in `NSNumber`s
    let delayTimesForIndexes: [Int: TimeInterval]

    /// Number of valid frames; equal to `delayTimes.count`
    let frameCount: Int

    /// Allow to cap the cache size; 0 means no specific limit (default)
    var frameCacheSizeMax: FrameCacheSize = .noLimit

    /// This is the definite value the frame cache needs to size itself to.
    var frameCacheSizeCurrent: Int {
        var frameCacheSizeCurrent = frameCacheSizeOptimal

        if frameCacheSizeMax > FrameCacheSize.noLimit {
            frameCacheSizeCurrent = min(frameCacheSizeCurrent, frameCacheSizeMax)
        }

        if frameCacheSizeMaxInternal > FrameCacheSize.noLimit {
            frameCacheSizeCurrent = min(frameCacheSizeCurrent, frameCacheSizeMaxInternal)
        }

        return frameCacheSizeCurrent.value
    }

    /// The optimal number of frames to cache based on image size & number of frames
    private let frameCacheSizeOptimal: FrameCacheSize

    /// Allow to cap the cache size e.g. when memory warnings occur; 0 means no specific limit (default)
    private var frameCacheSizeMaxInternal: FrameCacheSize = .noLimit

    /// Most recently requested frame index
    private var requestedFrameIndex: Int?

    private var cachedFramesForIndexes: [Int: UIImage] = [:]

    /// Indexes of cached frames
    private var cachedFrameIndexes: IndexSet = []

    /// Indexes of frames that are currently produced in the background
    private var requestedFrameIndexes: IndexSet = []

    /// Default index set with the full range of indexes
    private let allFramesIndexSet: IndexSet

    private var memoryWarningCount: Int = 0

    private lazy var serialQueue = DispatchQueue(label: "com.flipboard.framecachingqueue")

    private var weakProxy: CacheSettingProxy?

    weak var debugDelegate: FLAnimatedImageDebugDelegate?

    // MARK: - Lifecycle

    init?(data: Data, optimalFrameCacheSize: FrameCacheSize = .noLimit, predrawingEnabled: Bool = true) {
        guard !data.isEmpty else {
            Self.log(.error, "No animated GIF data supplied.")
            return nil
        }

        self.data = data
        self.isPredrawingEnabled = predrawingEnabled

        // Early return on failure!
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            Self.log(.error, "Failed to `CGImageSourceCreateWithData` for animated GIF data \(data)")
            return nil
        }

        self.imageSource = imageSource

        // Early return if not GIF!
        guard let imageSourceContainerType = CGImageSourceGetType(imageSource), UTTypeConformsTo(imageSourceContainerType, kUTTypeGIF) else {
            Self.log(.error, "Supplied data is of type \(String(describing: CGImageSourceGetType(imageSource))) and doesn't seem to be GIF data \(data)")
            return nil
        }

        // Get `LoopCount`
        guard
            let imageProperties = CGImageSourceCopyProperties(imageSource, nil),
            let gifProperties = (imageProperties as NSDictionary).object(forKey: kCGImagePropertyGIFDictionary) as? NSDictionary,
            let loopCount = gifProperties.object(forKey: kCGImagePropertyGIFLoopCount) as? Int else {
            return nil
        }
        self.loopCount = loopCount

        // Iterate through frame images
        let imageCount = CGImageSourceGetCount(imageSource)
        var skippedFrameCount: Int = 0

        // Handle poster frame outside the for-loop so we can set it immutably
        let posterFrame: (Int, UIImage)? = (0..<imageCount).compactMapFirst { i in
            guard let frameImageRef = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else { return nil }
            let frameImage = UIImage(cgImage: frameImageRef)
            return (i, frameImage)
        }

        guard let (posterFrameIndex, posterImage) = posterFrame else {
            return nil
        }

        self.posterImage = posterImage

        // Set its size to proxy our size.
        self.size = posterImage.size

        // Remember index of poster image so we never purge it; also add it to the cache.
        self.posterImageFrameIndex = posterFrameIndex
        self.cachedFramesForIndexes[posterImageFrameIndex] = posterImage
        self.cachedFrameIndexes.insert(self.posterImageFrameIndex)

        var delayTimes: [Int: TimeInterval] = [:]

        for i in 0..<imageCount {
            if CGImageSourceCreateImageAtIndex(imageSource, i, nil) != nil {
                // Get `DelayTime`
                let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as NSDictionary?
                let framePropertiesGIF = frameProperties?.object(forKey: kCGImagePropertyGIFDictionary) as? NSDictionary

                // Try to use the unclamped delay time; fall back to the normal delay time.
                var delayTime: TimeInterval
                // If we don't get a delay time from the properties, fall back to `Constants.defaultDelay`
                if let time = framePropertiesGIF?.object(forKey: kCGImagePropertyGIFUnclampedDelayTime) as? Double {
                    delayTime = time
                } else if let time = framePropertiesGIF?.object(forKey: kCGImagePropertyGIFDelayTime) as? Double {
                    delayTime = time
                } else {
                    Self.log(.info, "Falling back to preceding delay time for frame \(i) because none found in GIF properties \(String(describing: frameProperties))")
                    delayTime = delayTimes[i - 1] ?? Constants.frameDefaultDelay
                }

                // Support frame delays as low as `kDelayTimeIntervalMinimum`, with anything below being rounded up to `kDelayTimeIntervalDefault` for legacy compatibility.
                // To support the minimum even when rounding errors occur, use an epsilon when comparing. We downcast to float because that's what we get for delayTime from ImageIO.
                if Float(delayTime) < Float(Constants.frameMinimumDelay) - .ulpOfOne {
                    Self.log(.info, "Rounding frame \(i)'s `delayTime` from \(delayTime)  up to default \(Constants.frameDefaultDelay) (minimum supported: \(Constants.frameMinimumDelay)).")
                    delayTime = Constants.frameDefaultDelay
                }

                delayTimes[i] = delayTime
            } else {
                skippedFrameCount += 1
                Self.log(.info, "Dropping frame \(i) because failed to `CGImageSourceCreateImageAtIndex` with image source.")
            }
        }

        self.frameCount = imageCount
        self.delayTimesForIndexes = delayTimes

        if frameCount == 0 {
            Self.log(.info, "Failed to create any valid frames for GIF with properties \(imageProperties)")
        } else if frameCount == 1 {
            // Warn when we only have a single frame but return a valid GIF.
            Self.log(.info, "Created valid GIF but with only a single frame. Image properties: \(imageProperties)")
        } else {
            // We have multiple frames, rock on!
        }

        let MEGABYTE: CGFloat = 1_024 * 1_024

        let maxOptimalSize: FrameCacheSize
        if optimalFrameCacheSize == .noLimit {
            // Calculate the optimal frame cache size: try choosing a larger buffer window depending on the predicted image size.
            // It's only dependent on the image size & number of frames and never changes.
            let animatedImageDataSize = CGFloat((self.posterImage.cgImage?.bytesPerRow ?? 0) * Int(self.size.height) * (self.frameCount - skippedFrameCount)) / MEGABYTE

            if animatedImageDataSize <= CGFloat(DataSizeCategory.all.rawValue) {
                maxOptimalSize = FrameCacheSize(integerLiteral: frameCount)
            } else if animatedImageDataSize <= CGFloat(DataSizeCategory.default.rawValue) {
                // This value doesn't depend on device memory much because if we're not keeping all frames in memory we will always
                // be decoding 1 frame up ahead per 1 frame that gets played and at this point we might as well just keep a small
                // buffer just large enough to keep from running out of frames.
                maxOptimalSize = .default
            } else {
                // The predicted size exceeds the limits to build up a cache and we go into low memory mode from the beginning.
                maxOptimalSize = .lowMemory
            }
        } else {
            // Use the provided value.
            maxOptimalSize = optimalFrameCacheSize
        }

        // In any case, cap the optimal cache size at the frame count.
        self.frameCacheSizeOptimal = min(FrameCacheSize(integerLiteral: frameCount), maxOptimalSize)

        // Convenience/minor performance optimization; keep an index set handy with the full range to return in `-frameIndexesToCache`.

        self.allFramesIndexSet = IndexSet(integersIn: 0..<frameCount)

        super.init()

        self.weakProxy = CacheSettingProxy(self)

        // Register this instance in the weak table for memory notifications. The NSHashTable will clean up after itself when we're gone.
        // Note that FLAnimatedImages can be created on any thread, so the hash table must be locked.
        objc_sync_enter(FLAnimatedImage.allAnimatedImagesWeak)
        FLAnimatedImage.allAnimatedImagesWeak.add(self)
        objc_sync_exit(FLAnimatedImage.allAnimatedImagesWeak)
    }

    // MARK: - Public Methods

    // See header for more details.
    // Note: both consumer and producer are throttled: consumer by frame timings and producer by the available memory (max buffer window size).
    func imageLazilyCachedAt(index: Int) -> UIImage? {

        // Early return if the requested index is beyond bounds.
        // Note: We're comparing an index with a count and need to bail on greater than or equal to.
        if index >= self.frameCount {
            Self.log(.warn, "Skipping requested frame %lu beyond bounds (total frame count: \(index)) for animated image: \(frameCount)")
            return nil
        }

        // Remember requested frame index, this influences what we should cache next.
        self.requestedFrameIndex = index

        self.debugDelegate?.animatedImage(self, didRequestCachedFrame: index)

        // Quick check to avoid doing any work if we already have all possible frames cached, a common case.
        if cachedFramesForIndexes.count < self.frameCount {
            // If we have frames that should be cached but aren't and aren't requested yet, request them.
            // Exclude existing cached frames, frames already requested, and specially cached poster image.
            var frameIndexesToAddToCache = frameIndexesToCache()

            frameIndexesToAddToCache.subtract(cachedFrameIndexes)
            frameIndexesToAddToCache.subtract(requestedFrameIndexes)
            frameIndexesToAddToCache.remove(posterImageFrameIndex)

            // Asynchronously add frames to our cache.
            if !frameIndexesToAddToCache.isEmpty {
                addFrameIndexesToCache(frameIndexesToAddToCache)
            }
        }

        // Get the specified image.
        let image = cachedFramesForIndexes[index]

        // Purge if needed based on the current playhead position.
        purgeFrameCacheIfNeeded()

        return image
    }

    /// Only called once from `imageLazilyCachedAtIndex` but factored into its own method for logical grouping.
    private func addFrameIndexesToCache(_ frameIndexesToAddToCache: IndexSet) {
        let requestedFrameIndex = requestedFrameIndex ?? 0

        // Order matters. First, iterate over the indexes starting from the requested frame index.
        // Then, if there are any indexes before the requested frame index, do those.
        let firstRange = IndexSet(integersIn: requestedFrameIndex..<frameCount)
        let secondRange = IndexSet(integersIn: 0..<requestedFrameIndex)
        if firstRange.count + secondRange.count != frameCount {
            Self.log(.warn, "Two-part frame cache range doesn't equal full range.")
        }

        // Add to the requested list before we actually kick them off, so they don't get into the queue twice.
        requestedFrameIndexes.formUnion(frameIndexesToAddToCache)

        // Start streaming requested frames in the background into the cache.
        // Avoid capturing self in the block as there's no reason to keep doing work if the animated image went away.
        serialQueue.async { [weak self] in
            // Produce and cache next needed frame.
            let block: (Int) -> Void = { index in
#if DEBUG
                let predrawBeginTime = CACurrentMediaTime()
#endif
                let image = self?.image(at: index)
#if DEBUG
                let predrawDuration = CACurrentMediaTime() - predrawBeginTime
                var slowdownDuration: TimeInterval = 0
                if let predrawingSlowdownFactor = self?.debugDelegate?.animatedImagePredrawingSlowdownFactor(for: self!) {
                    slowdownDuration = (predrawDuration * predrawingSlowdownFactor) - predrawingSlowdownFactor
                    Thread.sleep(forTimeInterval: slowdownDuration)
                }
                Self.log(.verbose, "Predrew frame \(index) in \((predrawDuration + slowdownDuration) * 1_000) ms for animated image: \(String(describing: self))")
#endif

                // The results get returned one by one as soon as they're ready (and not in batch).
                // The benefits of having the first frames as quick as possible outweigh building up a buffer to cope with potential hiccups when the CPU suddenly gets busy.
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    strongSelf.cachedFramesForIndexes[index] = image
                    strongSelf.cachedFrameIndexes.insert(index)
                    strongSelf.requestedFrameIndexes.remove(index)
                    strongSelf.debugDelegate?.animatedImage(strongSelf, didUpdateCachedFrames: strongSelf.cachedFrameIndexes)
                }
            }

            firstRange.intersection(frameIndexesToAddToCache).forEach(block)
            secondRange.intersection(frameIndexesToAddToCache).forEach(block)
        }
    }

    // MARK: - Private Methods

    // MARK: Frame Loading

    private func image(at index: Int) -> UIImage? {
        // It's very important to use the cached `imageSource` since the random access to a frame with `CGImageSourceCreateImageAtIndex` turns from an O(1) into an O(n) operation when re-initializing the image source every time.
        // Early return for nil
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else { return nil }

        let image = UIImage(cgImage: imageRef)

        // Loading in the image object is only half the work, the displaying image view would still have to synchronosly wait and decode the image, so we go ahead and do that here on the background thread.
        return isPredrawingEnabled ? predrawnImage(image: image) : image
    }

    // MARK: Frame Caching

    private func frameIndexesToCache() -> IndexSet {
        // Quick check to avoid building the index set if the number of frames to cache equals the total frame count.
        guard frameCacheSizeCurrent != frameCount else {
            return allFramesIndexSet
        }

        guard let requestedFrameIndex = requestedFrameIndex else {
            return cachedFrameIndexes
        }

        var indexesToCache = IndexSet()

        // Add indexes to the set in two separate blocks- the first starting from the requested frame index, up to the limit or the end.
        // The second, if needed, the remaining number of frames beginning at index zero.
        let firstLength = min(frameCacheSizeCurrent, frameCount - requestedFrameIndex)
        let firstRange = requestedFrameIndex..<requestedFrameIndex + firstLength
        indexesToCache.insert(integersIn: firstRange)

        let secondLength = frameCacheSizeCurrent - firstLength
        if secondLength > 0 {
            let secondRange = 0..<secondLength
            indexesToCache.insert(integersIn: secondRange)
        }

        // Double check our math, before we add the poster image index which may increase it by one.
        if indexesToCache.count != frameCacheSizeCurrent {
            Self.log(.warn, "Number of frames to cache doesn't equal expected cache size.")
        }

        indexesToCache.insert(posterImageFrameIndex)

        return indexesToCache
    }

    private func purgeFrameCacheIfNeeded () {
        // Purge frames that are currently cached but don't need to be.
        // But not if we're still under the number of frames to cache.
        // This way, if all frames are allowed to be cached (the common case), we can skip all the `NSIndexSet` math below.
        guard cachedFrameIndexes.count > frameCacheSizeCurrent else { return }

        var indexesToPurge = cachedFrameIndexes
        indexesToPurge.subtract(frameIndexesToCache())

        indexesToPurge.forEach { index in
            cachedFrameIndexes.remove(index)
            cachedFramesForIndexes.removeValue(forKey: index)
            // Note: Don't `CGImageSourceRemoveCacheAtIndex` on the image source for frames that we don't want cached any longer to maintain O(1) time access.

            DispatchQueue.main.async {
                self.debugDelegate?.animatedImage(self, didUpdateCachedFrames: self.cachedFrameIndexes)
            }
        }
    }

    private func growFrameCacheSizeAfterMemoryWarning() {
        frameCacheSizeMaxInternal = FrameCacheSize.growAfterMemoryWarning
        Self.log(.debug, "Grew frame cache size max to \(frameCacheSizeMaxInternal) after memory warning for animated image: \(self)")

        // Schedule resetting the frame cache size max completely after a while.
        if let weakProxy = weakProxy {
            weakProxy.perform(#selector(weakProxy.resetFrameCacheSizeMaxInternal), with: nil, afterDelay: Constants.cacheResetDelay)

        }
    }

    private func resetFrameCacheSizeMaxInternal() {
        frameCacheSizeMaxInternal = FrameCacheSize.noLimit
        Self.log(.warn, "Reset frame cache size max (current frame cache size: \(frameCacheSizeCurrent) for animated image: \(self)")
    }

    // MARK: System Memory Warnings Notification Handler

    @objc
    func didReceiveMemoryWarning(_ notification: Notification) {
        memoryWarningCount += 1

        // If we were about to grow larger, but got rapped on our knuckles by the system again, cancel.
        if let weakProxy = weakProxy {
            NSObject.cancelPreviousPerformRequests(withTarget: weakProxy, selector: #selector(weakProxy.growFrameCacheSizeAfterMemoryWarning), object: nil)
            NSObject.cancelPreviousPerformRequests(withTarget: weakProxy, selector: #selector(weakProxy.resetFrameCacheSizeMaxInternal), object: nil)
        }

        // Go down to the minimum and by that implicitly immediately purge from the cache if needed to not get jettisoned by the system and start producing frames on-demand.
        Self.log(.debug, "Attempt setting frame cache size max to \(FrameCacheSize.lowMemory) (previous was \(frameCacheSizeMaxInternal) after memory warning \(memoryWarningCount) for animated image: \(self)")
        frameCacheSizeMaxInternal = FrameCacheSize.lowMemory

        // Schedule growing larger again after a while, but cap our attempts to prevent a periodic sawtooth wave (ramps upward and then sharply drops) of memory usage.
        //
        // [mem]^     (2)   (5)  (6)        1) Loading frames for the first time
        //   (*)|      ,     ,    ,         2) Mem warning #1; purge cache
        //      |     /| (4)/|   /|         3) Grow cache size a bit after a while, if no mem warning occurs
        //      |    / |  _/ | _/ |         4) Try to grow cache size back to optimum after a while, if no mem warning occurs
        //      |(1)/  |_/   |/   |__(7)    5) Mem warning #2; purge cache
        //      |__/   (3)                  6) After repetition of (3) and (4), mem warning #3; purge cache
        //      +---------------------->    7) After 3 mem warnings, stay at minimum cache size
        //                            [t]
        //                                  *) The mem high water mark before we get warned might change for every cycle.
        //
        if memoryWarningCount - 1 <= Constants.cacheGrowAttemptsMax, let weakProxy = weakProxy {
            weakProxy.perform(#selector(weakProxy.growFrameCacheSizeAfterMemoryWarning), with: nil, afterDelay: Constants.cacheGrowDelay)
        }

        // Note: It's not possible to get the level of a memory warning with a public API: http://stackoverflow.com/questions/2915247/iphone-os-memory-warnings-what-do-the-different-levels-mean/2915477#2915477
    }

    // MARK: Image Decoding

    /// Decodes the image's data and draws it off-screen fully in memory; it's thread-safe and hence can be called on a background thread.
    /// On success, the returned object is a new `UIImage` instance with the same content as the one passed in.
    /// On failure, the returned object is the unchanged passed in one; the data will not be predrawn in memory though and an error will be logged.
    /// First inspired by & good Karma to: https://gist.github.com/steipete/1144242
    private func predrawnImage(image imageToPredraw: UIImage) -> UIImage {
        guard let cgImage = imageToPredraw.cgImage else { return imageToPredraw }

        // Always use a device RGB color space for simplicity and predictability what will be going on.
        let colorSpaceDeviceRGBRef = CGColorSpaceCreateDeviceRGB()

        // Even when the image doesn't have transparency, we have to add the extra channel because Quartz doesn't support other pixel formats than 32 bpp/8 bpc for RGB:
        // kCGImageAlphaNoneSkipFirst, kCGImageAlphaNoneSkipLast, kCGImageAlphaPremultipliedFirst, kCGImageAlphaPremultipliedLast
        // (source: docs "Quartz 2D Programming Guide > Graphics Contexts > Table 2-1 Pixel formats supported for bitmap graphics contexts") - Latest Checked Date: Nov 1st 2015
        let numberOfComponents = colorSpaceDeviceRGBRef.numberOfComponents + 1 // 4: RGB + A

        let width = imageToPredraw.size.width
        let height = imageToPredraw.size.height
        let bitsPerComponent = Int(CHAR_BIT)
        let bitsPerPixel = bitsPerComponent * numberOfComponents
        let bytesPerPixel = bitsPerPixel / Int(BYTE_SIZE)
        let bytesPerRow = bytesPerPixel * Int(width)

        let bitmapInfo: CGBitmapInfo = []
        var alphaInfo: CGImageAlphaInfo = cgImage.alphaInfo
        // If the alpha info doesn't match to one of the supported formats (see above), pick a reasonable supported one.
        // "For bitmaps created in iOS 3.2 and later, the drawing environment uses the premultiplied ARGB format to store the bitmap data." (source: docs)
        switch alphaInfo {
        case .none, .alphaOnly:
            alphaInfo = .noneSkipFirst
        case .first:
            alphaInfo = .premultipliedFirst
        case .last:
            alphaInfo = .premultipliedLast
        default:
            break
        }
        // "The constants for specifying the alpha channel information are declared with the `CGImageAlphaInfo` type but can be passed to this parameter safely." (source: docs)
        let info = bitmapInfo.rawValue | alphaInfo.rawValue

        // Create our own graphics context to draw to; `UIGraphicsGetCurrentContext`/`UIGraphicsBeginImageContextWithOptions` doesn't create a new context but returns the current one which isn't thread-safe (e.g. main thread could use it at the same time).
        // Note: It's not worth caching the bitmap context for multiple frames ("unique key" would be `width`, `height` and `hasAlpha`), it's ~50% slower. Time spent in libRIP's `CGSBlendBGRA8888toARGB8888` suddenly shoots up -- not sure why.
        let bitmapContextRef = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpaceDeviceRGBRef, bitmapInfo: info)

        // Early return on failure!
        guard let bitmapContextRef = bitmapContextRef else {
            Self.log(.error, "Failed to `CGBitmapContextCreate` with color space \(colorSpaceDeviceRGBRef) and parameters (width: \(width) height: \(height) bitsPerComponent: \(bitsPerComponent) bytesPerRow: \(bytesPerRow)) for image \(imageToPredraw)")
            return imageToPredraw
        }

        // Draw image in bitmap context and create image by preserving receiver's properties.
        bitmapContextRef.draw(cgImage, in: CGRect(x: 0, y: 0, width: imageToPredraw.size.width, height: imageToPredraw.size.height))

        // Early return on failure!
        guard let predrawnImageRef = bitmapContextRef.makeImage() else {
            Self.log(.error, "Failed to `imageWithCGImage:scale:orientation:`")
            return imageToPredraw
        }

        return UIImage(cgImage: predrawnImageRef, scale: imageToPredraw.scale, orientation: imageToPredraw.imageOrientation)
    }

    deinit {
        if let weakProxy = weakProxy {
            NSObject.cancelPreviousPerformRequests(withTarget: weakProxy)
        }
    }
}

// MARK: - Logging

extension FLAnimatedImage {

    enum LogLevel: Int, Comparable {
        case none
        case error
        case warn
        case info
        case debug
        case verbose

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private static var logLevel: LogLevel = .none
    private static var logBlock: ((String, LogLevel) -> Void)?

    override var description: String {
        return super.description + " size = \(size) frameCount \(frameCount)"
    }

    static func logging(_ logLevel: LogLevel, _ logBlock: @escaping (String, LogLevel) -> Void) {
        Self.logLevel = logLevel
        Self.logBlock = logBlock
    }

    static func log(_ level: LogLevel, _ message: String) {
        if level <= logLevel {
            logBlock?(message, level)
        }
    }
}

extension FLAnimatedImage {

    enum DataSizeCategory: Int {
        /// All frames permanently in memory (be nice to the CPU)
        case all = 10
        /// A frame cache of default size in memory (usually real-time performance and keeping low memory profile)
        case `default` = 75
        /// Only keep one frame at the time in memory (easier on memory, slowest performance)
        case onDemand = 250
    }

    enum FrameCacheSize: Comparable, ExpressibleByIntegerLiteral {
        /// 0 means no specific limit
        case noLimit
        /// The minimum frame cache size; this will produce frames on-demand.
        case lowMemory
        /// If we can produce the frames faster than we consume, one frame ahead will already result in a stutter-free playback.
        case growAfterMemoryWarning
        /// Build up a comfy buffer window to cope with CPU hiccups etc.
        case `default`
        case custom(Int)

        var value: Int {
            switch self {
            case .noLimit: return 0
            case .lowMemory: return 1
            case .growAfterMemoryWarning: return 2
            case .default: return 5
            case .custom(let value): return value
            }
        }

        init(integerLiteral: Int) {
            self = .custom(integerLiteral)
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.value < rhs.value
        }
    }
}

private extension Sequence {
    // Functionally the same as Array.compactMap().first(), except returns immediately upon finding the first item.
    func compactMapFirst<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> ElementOfResult? {
        for item in self {
            if let result = try transform(item) {
                return result
            }
        }

        return nil
    }
}

private extension FLAnimatedImage {
    class CacheSettingProxy: NSObject {
        weak var image: FLAnimatedImage?

        init(_ image: FLAnimatedImage) {
            self.image = image
        }

        @objc
        func growFrameCacheSizeAfterMemoryWarning() {
            image?.growFrameCacheSizeAfterMemoryWarning()
        }

        @objc
        func resetFrameCacheSizeMaxInternal() {
            image?.resetFrameCacheSizeMaxInternal()
        }
    }
}
