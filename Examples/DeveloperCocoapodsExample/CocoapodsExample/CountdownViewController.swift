//
//  CountdownViewController.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2024-06-26.
//

import UIKit
import AppcuesKit
import SwiftUI

@available(iOS 14.0, *)
class CountdownViewController: UIViewController, AppcuesCustomFrameViewController {
    struct Config: Decodable {
        let endDate: String
        let tintColor: String?
    }

    let config: Config

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
        preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    func setup() {
        let tintColor = UIColor(hex: config.tintColor) ?? .black
        let viewController = UIHostingController(rootView: CountdownTimerView(endDate: config.endDate, tintColor: tintColor))

        let swiftuiView = viewController.view!
        swiftuiView.translatesAutoresizingMaskIntoConstraints = false
        swiftuiView.backgroundColor = .clear

        addChild(viewController)
        view.addSubview(swiftuiView)

        NSLayoutConstraint.activate([
            swiftuiView.topAnchor.constraint(equalTo: view.topAnchor),
            swiftuiView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swiftuiView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swiftuiView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        viewController.didMove(toParent: self)
    }
}

// https://medium.com/@setsailswift/daily-countdown-timer-in-swiftui-7b2e8c594640

@available(iOS 14.0, *)
struct CountdownTimerView: View {
    @StateObject var viewModel: CountdownTimerViewModel

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let tintColor: Color

    private var hasCountdownCompleted: Bool {
        viewModel.hasCountdownCompleted
    }

    init(endDate: String, tintColor: UIColor) {
        if #available(iOS 15.0, *) {
            self.tintColor = Color(uiColor: tintColor)
        } else {
            self.tintColor = Color.black
        }

        _viewModel = StateObject(wrappedValue: CountdownTimerViewModel(endDate: endDate))
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack {
                Text(String(format: "%02d", viewModel.day))
                    .font(.system(size: 22, weight: .bold))
                Text("day")
                    .textCase(.uppercase)
                    .font(.system(size: 11))
            }
            colon
            VStack {
                Text(String(format: "%02d", viewModel.hour))
                    .font(.system(size: 22, weight: .bold))
                Text("hour")
                    .textCase(.uppercase)
                    .font(.system(size: 11))
            }
            colon
            VStack {
                Text(String(format: "%02d", viewModel.minute))
                    .font(.system(size: 22, weight: .bold))
                Text("min")
                    .textCase(.uppercase)
                    .font(.system(size: 11))
            }
            colon
            VStack {
                Text(String(format: "%02d", viewModel.second))
                    .font(.system(size: 22, weight: .bold))
                Text("sec")
                    .textCase(.uppercase)
                    .font(.system(size: 11))
            }
        }
        .foregroundColor(tintColor)
        .onReceive(timer) { _ in
            if hasCountdownCompleted {
                timer.upstream.connect().cancel() // turn off timer
            } else {
                viewModel.updateTimer()
            }
        }
    }

    var colon: some View {
        Text(":")
            .font(.system(size: 22, weight: .bold))
    }
}

@MainActor
class CountdownTimerViewModel: ObservableObject {
    // These will be used to store the current value of
    // the unit on the clock, which then notifies the view
    // of a change to display when the original value is updated
    @Published var day: Int = 0
    @Published var hour: Int = 0
    @Published var minute: Int = 0
    @Published var second: Int = 0

    var endDate: Date
    var hasCountdownCompleted: Bool {
        Date() > endDate
    }

    init(endDate: String) {
        let dateFormatter = ISO8601DateFormatter()
        self.endDate = dateFormatter.date(from: endDate) ?? Date()
        updateTimer()
    }

    func updateTimer() {
        let calendar = Calendar(identifier: .gregorian)
        let timeValue = calendar.dateComponents([.day, .hour, .minute, .second], from: Date(), to: endDate)

        if !hasCountdownCompleted,
           let day = timeValue.day,
           let hour = timeValue.hour,
           let minute = timeValue.minute,
           let second = timeValue.second {
            self.day = day
            self.hour = hour
            self.minute = minute
            self.second = second
        }
    }
}

extension UIColor {

    /// Init `UIColor` from an experience JSON model value.
    convenience init?(hex: String?) {
        guard let hex = hex?.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) else { return nil }

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        // swiftlint:disable:next identifier_name
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // RGBA (32-bit)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}
