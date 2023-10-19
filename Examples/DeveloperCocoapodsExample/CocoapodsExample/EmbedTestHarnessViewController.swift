//
//  EmbedTestHarnessViewController.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2023-06-26.
//

import UIKit
import AppcuesKit

class EmbedTestHarnessView: UIScrollView {
    weak var frame1: AppcuesFrameView?
    weak var frame2: AppcuesFrameView?

    let stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.spacing = 12
        return view
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = .systemBackground

        addSubview(stackView)

        stackView.addArrangedSubview(makeLabel("Embed Test Harness", textStyle: .title1))
        stackView.addArrangedSubview(makeLabel("About this screen", textStyle: .title3))
        // swiftlint:disable:next line_length
        stackView.addArrangedSubview(makeLabel("This screen doesn't automatically track any Appcues screens or events. Not automatically tracking allows you to simulate different combinations of screens/events and how they impact the embed rendering lifecycle.", textStyle: .body))
        stackView.addArrangedSubview(makeLabel("Use the 3 dots menu to trigger events and toggle embed frames.", textStyle: .body))

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeLabel(_ text: String, textStyle: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: textStyle)
        label.text = text

        return label
    }

    func toggleFrame(id: String, viewController: UIViewController) {
        if id == "frame1" {
            if frame1 == nil {
                let frame = AppcuesFrameView()
                stackView.insertArrangedSubview(frame, at: 1)
                frame1 = frame
                Appcues.shared.register(frameID: id, for: frame, on: viewController)
            } else {
                frame1?.removeFromSuperview()
            }
        } else if id == "frame2" {
            if frame2 == nil {
                let frame = AppcuesFrameView()
                stackView.insertArrangedSubview(frame, at: 3)
                frame2 = frame
                Appcues.shared.register(frameID: id, for: frame, on: viewController)
            } else {
                frame2?.removeFromSuperview()
            }
        }
    }
}

class EmbedTestHarnessViewController: UIViewController {

    lazy var testHarnessView = EmbedTestHarnessView()

    override func loadView() {
        view = testHarnessView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Embed Test Harness"

        if #available(iOS 14.0, *) {
            let menu = UIMenu(title: "", children: [
                UIAction(title: "Track Screen", image: UIImage(systemName: "rectangle.portrait.on.rectangle.portrait")) { _ in
                    Appcues.shared.screen(title: "Embed Harness")
                },
                UIAction(title: "Track Event", image: UIImage(systemName: "hand.tap")) { _ in
                    Appcues.shared.track(name: "event3")
                },
                UIAction(title: "Toggle 'frame1'", image: UIImage(systemName: "photo.artframe")) { [weak self] _ in
                    guard let self = self else { return }
                    self.testHarnessView.toggleFrame(id: "frame1", viewController: self)
                },
                UIAction(title: "Toggle 'frame2'", image: UIImage(systemName: "photo.artframe")) { [weak self] _ in
                    guard let self = self else { return }
                    self.testHarnessView.toggleFrame(id: "frame2", viewController: self)
                },
                UIAction(title: "Identify 'user-1'", image: UIImage(systemName: "person")) { _ in
                    Appcues.shared.identify(userID: "user-1")
                }
            ])

            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        }
    }
}
