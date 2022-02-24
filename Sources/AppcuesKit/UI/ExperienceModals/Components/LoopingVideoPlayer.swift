//
//  LoopingVideoPlayer.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-14.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI
import AVKit

internal struct LoopingVideoPlayer {
    let url: URL
}

extension LoopingVideoPlayer: UIViewRepresentable {

    func makeUIView(context: Context) -> LoopingVideoView {
        LoopingVideoView(url: url)
    }

    func updateUIView(_ uiView: LoopingVideoView, context: Context) {
        // nothing to update, the content is constant
    }
}

extension LoopingVideoPlayer {
    class LoopingVideoView: UIView {

        private static let key = "playable"
        // Using AVPlayerLayer as our standard layer makes this a AVPlayer compatible view
        override static var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
        // need to retain a reference
        private var looper: AVPlayerLooper?

        init(url: URL) {
            super.init(frame: .zero)

            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: [LoopingVideoView.key]) { [weak self] in
                var error: NSError?
                let status = asset.statusOfValue(forKey: LoopingVideoView.key, error: &error)
                if case .loaded = status {
                    self?.playLoopingAsset(with: asset)
                }
            }

            // Fix the tiny border that shows around the video (http://www.openradar.me/35158514)
            playerLayer?.shouldRasterize = true
            playerLayer?.rasterizationScale = UIScreen.main.scale
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func playLoopingAsset(with asset: AVAsset) {
            DispatchQueue.main.async { [weak self] in
                let queuePlayer = AVQueuePlayer()
                self?.playerLayer?.player = queuePlayer
                self?.looper = AVPlayerLooper(player: queuePlayer, templateItem: AVPlayerItem(asset: asset))
                queuePlayer.play()
            }
        }
    }
}
