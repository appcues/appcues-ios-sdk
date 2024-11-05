//
//  LiveStreamViewController.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2024-06-27.
//

import Foundation
import AppcuesKit
import AVKit

#if DEBUG
extension LiveStreamViewController {
    static var debugConfig: [String: Any]? {
        [
            "url": "https://zssd-koala.hls.camzonecdn.com/CamzoneStreams/zssd-koala/Playlist.m3u8",
            "showControls": false,
            "isMuted": true
        ]
    }
}
#endif

class LiveStreamViewController: UIViewController, AppcuesCustomComponentViewController {
    struct Config: Decodable {
        let url: URL
        let showControls: Bool
        let isMuted: Bool

        enum CodingKeys: CodingKey {
            case url
            case showControls
            case isMuted
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.url = try container.decode(URL.self, forKey: .url)
            self.showControls = try container.decodeIfPresent(Bool.self, forKey: .showControls) ?? true
            self.isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? false
        }
    }

    let config: Config
    let actionController: AppcuesExperienceActions

    var playerView: UIView?

    required init?(configuration: AppcuesKit.AppcuesExperiencePluginConfiguration, actionController: AppcuesExperienceActions) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.config = config
        self.actionController = actionController

        super.init(nibName: nil, bundle: nil)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        print(view.frame, view.intrinsicContentSize)
        preferredContentSize = CGSize(width: view.frame.width, height: view.frame.width * 0.5625)
    }

    func setup() {
        let player = AVPlayer(url: config.url)
        player.isMuted = config.isMuted

        let viewController = AVPlayerViewController()
        viewController.player = player
        viewController.showsPlaybackControls = config.showControls

        let playerView = viewController.view!
        playerView.translatesAutoresizingMaskIntoConstraints = false

        addChild(viewController)
        view.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        viewController.didMove(toParent: self)

        self.playerView = playerView
        player.play()
    }
}
