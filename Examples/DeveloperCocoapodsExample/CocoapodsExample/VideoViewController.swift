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
        
        enum CodingKeys: CodingKey {
            case url
            case showControls
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.url = try container.decode(URL.self, forKey: .url)
            let controlVal = try container.decodeIfPresent(String.self, forKey: .showControls)
            self.showControls = (controlVal as NSString?)?.boolValue ?? true
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

    func setup() {
        let player = AVPlayer(url: config.url)

        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = config.showControls ?? true

        let playerView = vc.view!
        playerView.translatesAutoresizingMaskIntoConstraints = false

        addChild(vc)
        view.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        vc.didMove(toParent: self)

        self.playerView = playerView
        player.play()
    }

    override func viewDidLayoutSubviews() {
        preferredContentSize = CGSize(width: view.frame.width, height: view.frame.width * 0.5625)
    }
}
