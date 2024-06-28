//
//  VideoViewController.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2024-06-27.
//

import Foundation
import AppcuesKit
import AVKit

class VideoViewController: UIViewController, AppcuesCustomFrameViewController {
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
            let controlVal = try container.decodeIfPresent(String.self, forKey: .showControls)
            self.showControls = (controlVal as NSString?)?.boolValue ?? true
            let mutedVal = try container.decodeIfPresent(String.self, forKey: .isMuted)
            self.isMuted = (mutedVal as NSString?)?.boolValue ?? false
        }
    }

    let config: Config

    var playerView: UIView?

    required init?(configuration: AppcuesKit.AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.config = config

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
