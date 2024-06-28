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

    func setup() {
        let vc = UIHostingController(rootView: CountdownTimerView(endDate: config.endDate))

        let swiftuiView = vc.view!
        swiftuiView.translatesAutoresizingMaskIntoConstraints = false

        addChild(vc)
        view.addSubview(swiftuiView)

        NSLayoutConstraint.activate([
            swiftuiView.topAnchor.constraint(equalTo: view.topAnchor),
            swiftuiView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swiftuiView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swiftuiView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        vc.didMove(toParent: self)

        self.preferredContentSize.height = 60
    }
}

// https://medium.com/@setsailswift/daily-countdown-timer-in-swiftui-7b2e8c594640

@available(iOS 14.0, *)
struct CountdownTimerView: View {
    @StateObject var viewModel: CountdownTimerViewModel

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var hasCountdownCompleted: Bool {
        viewModel.hasCountdownCompleted
    }

    init(endDate: String) {
        _viewModel = StateObject(wrappedValue: CountdownTimerViewModel(endDate: endDate))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(spacing: 8) {
                    Text(String(format: "%02d", viewModel.day))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                    Text("day")
                        .textCase(.uppercase)
                        .font(.system(size: 11))
                }
                VStack(spacing: 8) {
                    colon
                    Spacer()
                        .frame(height: 15)
                }
                VStack(spacing: 8) {
                    Text(String(format: "%02d", viewModel.hour))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                    Text("hour")
                        .textCase(.uppercase)
                        .font(.system(size: 11))
                }
                VStack(spacing: 8) {
                    colon
                    Spacer()
                        .frame(height: 15)
                }
                VStack(spacing: 8) {
                    Text(String(format: "%02d", viewModel.minute))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                    Text("min")
                        .textCase(.uppercase)
                        .font(.system(size: 11))
                }
                VStack(spacing: 8) {
                    colon
                    Spacer()
                        .frame(height: 15)
                }
                VStack(spacing: 8) {
                    Text(String(format: "%02d", viewModel.second))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                    Text("sec")
                        .textCase(.uppercase)
                        .font(.system(size: 11))
                }
            }
        }
        .onReceive(timer) { _ in
            if hasCountdownCompleted {
                timer.upstream.connect().cancel() // turn off timer
            } else {
                viewModel.updateTimer()
            }
        }
    }
}

@available(iOS 14.0, *)
extension CountdownTimerView {
    private var colon: some View {
        Text(":")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.red)
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

    var endDate: Date = Date()
    var hasCountdownCompleted: Bool {
        Date() > endDate
    }

    init(endDate: String) {
        self.endDate =  parseDate(endDate)
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

//            progress = Float(endDate.timeIntervalSinceCurrentDate / initialTimeRemaining)
        } else {
//            progress = 0.0
        }
    }

    // Parse date from given string, identifying what format it matches.
    private func parseDate(_ dateString: String) -> Date {

        // Normally, you use DateFormatter to format date from a given string (i.e. "MM/dd/yy, yyyy-MM-dd, dd/MM/yy, etc).
        // But since we are formatting using the ISO 8601 format("yyyy-MM-dd’T’HH:mm:ssZ"), we can use ISO8601DateFormatter()
        // to create the date since the format is built into the class.
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: dateString) else {
            return Date()
        }

        return date
    }
}
