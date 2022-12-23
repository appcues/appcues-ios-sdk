//
//  EventsViewController.swift
//  AppcuesExample
//
//  Created by Matt on 2021-10-12.
//

import UIKit
import AppcuesKit

class EventsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Trigger Events")
    }

    @IBAction private func buttonOneTapped(_ sender: UIButton) {
        Appcues.shared.track(name: "event1")
        show(CrazyStyleViewController(variation: 123), sender: nil)
    }

    @IBAction private func buttonTwoTapped(_ sender: UIButton) {
        Appcues.shared.track(name: "event2")
    }

    @IBAction private func debugTapped(_ sender: Any) {
        Appcues.shared.debug()
    }
}

class CrazyStyleViewController: UIViewController {

    let variation: Int
    private lazy var styleView = CrazyStyleView(variation: variation)

    init(variation: Int) {
        self.variation = variation

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = styleView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Style \(variation)"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.tabBar.tintColor = styleView.theme.color.tintColor
        tabBarController?.tabBar.backgroundColor = styleView.theme.color.chromeColor
        navigationController?.navigationBar.tintColor = styleView.theme.color.tintColor
        navigationController?.navigationBar.backgroundColor = styleView.theme.color.chromeColor
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Appcues.shared.screen(title: "Style \(variation)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if #available(iOS 15.0, *) {
            tabBarController?.tabBar.tintColor = .tintColor
            tabBarController?.tabBar.backgroundColor = nil
            navigationController?.navigationBar.tintColor = .tintColor
            navigationController?.navigationBar.backgroundColor = nil
        }
    }
}

class CrazyStyleView: UIScrollView {

    let theme: (color: UIColor.Theme, font: UIFont.Theme)

    private lazy var contentView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        view.spacing = 8
        view.alignment = .fill
        view.distribution = .fill
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.numberOfLines = 0
        view.font = theme.font.heading
        view.textColor = theme.color.primaryBrandColor
        view.text = .random(length: 5)
        // TODO: hack to allow cloning a label
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.numberOfLines = 0
        view.font = theme.font.subheading
        view.textColor = theme.color.textColor
        view.text = .random(length: 15)
        // TODO: hack to allow cloning a label
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var primaryButton: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.titleLabel?.font = theme.font.body
        view.setTitleColor(theme.color.tintColor, for: .normal)
        view.backgroundColor = theme.color.secondaryBrandColor
        view.setTitle(.random(length: 3), for: .normal)
        return view
    }()

    init(variation: Int) {
        theme = (
            UIColor.themes.randomElement() ?? UIColor.themes[0],
            UIFont.themes.randomElement() ?? UIFont.themes[0]
        )

        super.init(frame: .zero)

        backgroundColor = .systemBackground

        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor)
        ])

        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(subtitleLabel)
        contentView.addArrangedSubview(primaryButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIFont {
    struct Theme {
        let heading: UIFont
        let subheading: UIFont
        let body: UIFont
        let additional: [UIFont]
    }

    static var themes: [Theme] = [
        Theme(
            heading: UIFont(name: "Lato-Black", size: 28)!,
            subheading: UIFont(name: "Lato-Bold", size: 22)!,
            body: UIFont(name: "Lato-Regular", size: 18)!,
            additional: []
        )
    ]
}

extension UIColor {
    struct Theme {
        let tintColor: UIColor
        let chromeColor: UIColor?
        let primaryBrandColor: UIColor
        let secondaryBrandColor: UIColor
        let textColor: UIColor
        let backgroundColor: UIColor
        let additionalBackgroundColors: [UIColor]
    }

    static var themes: [Theme] = [
        Theme(
            tintColor: UIColor(hex: "#13678A"),
            chromeColor: UIColor(hex: "#DAFDBA"),
            primaryBrandColor: UIColor(hex: "#13678A"),
            secondaryBrandColor: UIColor(hex: "#45C4B0"),
            textColor: UIColor(hex: "#012030"),
            backgroundColor: UIColor(hex: "#FFFFFF"),
            additionalBackgroundColors: [UIColor(hex: "#DAFDBA")])
    ]

    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

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

extension String {
    // swiftlint:disable:next line_length
    private static var text: String = "APPCUES MOBILE Improve mobile adoption in minutes Build and experiment with on-brand mobile experiences that improve user activation and adoption—no coding needed INCREASE APP ACTIVATION AND ADOPTION REDUCE TIME TO VALUE GET USERS COMING BACK INTO YOUR APP Talk to a product specialist The speed and flexibility thousands of customers have come to love for web now for native mobile apps You’re in control—take the wheel Build on-brand experiences make changes and iterate—on the fly in minutes no developer needed Speed is an advantage not an obstacle No need to resubmit your app to the App Store or Google Play or wait for users to update their app versions Instead get experiences in front of your users quickly for faster learning A cohesive experience across devices Understand your users product journeys and build a cohesive experience across web and mobile Before we would require a few days of dev work almost every release The ability to transition ownership to the product and design team is huge and will enable us to more effectively call out new features and benefits to our customers Kelly Nibley Sr Product Manager Mobile Apps Give users a reason to keep coming back to your app Shorten time to the aha moment increase app usage maximize conversion and retain users with customer-centric mobile experiences Get users to see the value faster Help new users get acquainted with your app by highlighting the benefits they can expect and the key steps they need to take Create stickiness with new features Communicate newly launched features and the value they will bring giving users another reason to come back And use deep linking to send them to the right screen to get started Increase revenue with perfectly timed upsells Use detailed targeting to create contextual relevant messages in-app to get users to upgrade or purchase an add-on at the most optimal time in their journeys And there’s even more use cases… Deliver important updates Share announcements like outages app updates or marketing events Grow feature usage Highlight unused features that can improve a user’s experience helping them get more value from your app Celebrate milestones Target users and congratulate them on achievements they’re making with your app Creating native mobile experiences has never been easier Take control of mobile adoption and build stunning in-app experiences in minutes with Appcues Mobile Open SDK for easy installation  Simple code-free builder Powerful targeting  Measure the impact Evaluate performance and determine which experiences are truly engaging your users with detailed analytics and reporting Frequently asked questions Have another question? Looking for more detail? Check out Appcues Docs! Appcues Docs What mobile environments are supported?  What can I use Appcues Mobile for? How do I choose the right solution for me? Don’t take our word for it Take a look for yourself Get a demo"

    static func random(length: Int) -> String {
        text.split(separator: " ").shuffled().prefix(length).joined(separator: " ")
    }
}
