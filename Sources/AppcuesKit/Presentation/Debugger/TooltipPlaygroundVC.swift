//
//  TooltipPlaygroundVC.swift
//  AppcuesKit
//
//  Created by Matt on 2023-01-31.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI
import Combine

// swiftlint:disable all

@available(iOS 14.0, *)
public class TooltipPlaygroundVC: UIViewController, AppcuesExperienceDelegate {

    let package: ExperiencePackage
    let model = KnobModel()

    private weak var appcues: Appcues?

    private var subscribers: [AnyCancellable] = []

    public init(instance: Appcues) {
        let traitComposer = instance.container.resolve(TraitComposing.self)
        let experienceData = ExperienceData(Experience.tooltip(knobData: model.knobData), trigger: .preview)

        package = try! traitComposer.package(experience: experienceData, stepIndex: .initial)
        appcues = instance

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Tooltip Playground"

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Launch", primaryAction: UIAction { [weak self] _ in self?.showPlayground() })

        observeModel()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showPlayground()

        appcues?.experienceDelegate = self
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        appcues?.experienceDelegate = nil
    }

    func showPlayground() {
        try! package.stepDecoratingTraitUpdater(0, nil)
        try! package.presenter {
            self.applyKnobs(self.model.knobData)
            self.showKnobs()
        }
    }

    func showKnobs() {
        if #available(iOS 15.0, *) {
            let knobViewController = ShakeDetectingHostViewController(rootView: TooltipKnobs(model: model))
            knobViewController.title = "Tooltip Knobs"

            let saveOptions = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Save Current Settings", image: UIImage(systemName: "square.and.arrow.down"), handler: { _ in
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let data = try! encoder.encode(self.model.knobData)
                    UserDefaults.standard.set(data, forKey: "settings")
                }),
                UIAction(title: "Apply Saved Settings", image: UIImage(systemName: "arrow.uturn.forward"), handler: { _ in
                    if let data = UserDefaults.standard.data(forKey: "settings"),
                        let decoded = try? JSONDecoder().decode(KnobData.self, from: data) {
                        self.model.knobData = decoded
                    }
                })
            ])

            let exportOptions = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Share Current Settings", image: UIImage(systemName: "square.and.arrow.up"), handler: { _ in
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    if let data = try? encoder.encode(self.model.knobData), let string = String(data: data, encoding: .utf8) {
                        let ac = UIActivityViewController(activityItems: [string], applicationActivities: nil)
                        knobViewController.present(ac, animated: true)
                    }
                }),
                UIAction(title: "Apply Settings From Clipboard", image: UIImage(systemName: "doc.on.clipboard"), handler: { _ in
                    if let data = UIPasteboard.general.string?.data(using: .utf8), let decoded = try? JSONDecoder().decode(KnobData.self, from: data) {
                        self.model.knobData = decoded
                    }
                })
            ])

            let menuItems = [
                saveOptions,
                exportOptions,
                UIAction(title: "Reset to Default", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in
                    self.model.knobData = KnobData()
                })
            ]

            knobViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "wrench.and.screwdriver"),
                menu: UIMenu(title: "Options", children: menuItems))

            knobViewController.motionEnded = { motion, _ in
                if motion == .motionShake {
                    knobViewController.dismiss(animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showKnobs()
                    }
                }
            }

            let navigationController = UINavigationController(rootViewController: knobViewController)
            navigationController.modalPresentationStyle = .pageSheet
            navigationController.sheetPresentationController?.detents = [.medium()]
            navigationController.sheetPresentationController?.largestUndimmedDetentIdentifier = .medium

            package.wrapperController.present(navigationController, animated: true)
        }
    }

    func observeModel() {
        model.$knobData
            .sink {
                self.applyKnobs($0)
            }
            .store(in: &subscribers)
    }

    func applyKnobs(_ data: KnobData) {
        guard let metadataDelegate = package.traitInstances.first?.metadataDelegate else {
            return
        }

        self.package.containerController.navigate(to: data.step, animated: data.enableAnimation)

        if let tooltipWrapper = package.wrapperController as?
ExperienceWrapperViewController<TooltipWrapperView> {
            tooltipWrapper.bodyView.preferredWidth = CGFloat(data.preferredWidth)
            tooltipWrapper.bodyView.pointerSize = data.hidePointer ? nil : CGSize(width: data.pointerBase, height: data.pointerLength)
            tooltipWrapper.bodyView.pointerCornerRadius = data.pointerCornerRadius
            let style = ExperienceComponent.Style(
                verticalAlignment: nil,
                horizontalAlignment: nil,
                paddingTop: nil,
                paddingLeading: nil,
                paddingBottom: nil,
                paddingTrailing: nil,
                marginTop: nil,
                marginLeading: nil,
                marginBottom: nil,
                marginTrailing: nil,
                height: nil,
                width: nil, // handled elsewhere
                fontName: nil,
                fontSize: nil,
                letterSpacing: nil,
                lineHeight: nil,
                textAlignment: nil,
                foregroundColor: nil,
                backgroundColor: ExperienceComponent.Style.DynamicColor(light: data.backgroundColor, dark: nil),
                backgroundGradient: nil,
                backgroundImage: nil,
                shadow: ExperienceComponent.Style.RawShadow(color: ExperienceComponent.Style.DynamicColor(light: data.shadowColor, dark: nil), radius: data.shadowRadius, x: data.shadowX, y: data.shadowY),
                cornerRadius: data.cornerRadius,
                borderColor: ExperienceComponent.Style.DynamicColor(light: data.borderColor, dark: nil),
                borderWidth: data.borderWidth)
            tooltipWrapper.configureStyle(style)
        }

        metadataDelegate.set([
            "keyholeShape": AppcuesBackdropKeyholeTrait.KeyholeShape(data.keyholeShape, cornerRadius: data.keyholeCorner, blurRadius: data.keyholeBlur),
            "keyholeSpread": CGFloat(data.keyholeSpread),
            "backdropBackgroundColor": UIColor(hex: data.backdropColor)
        ])

        if data.enableTarget {
            metadataDelegate.set([
                "contentPreferredPosition": ContentPosition(rawValue: data.contentPreferredPosition),
                "contentDistanceFromTarget": CGFloat(data.contentDistanceFromTarget),
                "targetRectangle": CGRect(
                    x: data.targetRelativeX * (self.view.window?.bounds.width ?? 0) + data.targetX,
                    y: data.targetRelativeY * (self.view.window?.bounds.height ?? 0) + data.targetY,
                    width: data.targetRelativeWidth * (self.view.window?.bounds.width ?? 0) + data.targetWidth,
                    height: data.targetRelativeHeight * (self.view.window?.bounds.height ?? 0) + data.targetHeight)
            ])
        } else {
            metadataDelegate.unset(keys: [ "contentPreferredPosition", "contentDistanceFromTarget", "targetRectangle" ])
        }

        if data.enableAnimation {
            metadataDelegate.set([
                "animationDuration": data.animationDuration,
                "animationEasing": AppcuesStepTransitionAnimationTrait.Easing(rawValue: data.animationEasing)
            ])
        } else {
            metadataDelegate.unset(keys: [ "animationDuration", "animationEasing" ])
        }
        metadataDelegate.publish()

    }

    public func canDisplayExperience(experienceID: String) -> Bool {
        // block all Appcues content
        false
    }

    public func experienceWillAppear() {}
    public func experienceDidAppear() {}
    public func experienceWillDisappear() {}
    public func experienceDidDisappear() {}
}

@available(iOS 14.0, *)
class ShakeDetectingHostViewController<Content: View>: UIHostingController<Content> {

    var motionEnded: ((UIEvent.EventSubtype, UIEvent?) -> Void)?

    override public func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        motionEnded?(motion, event)
    }
}

@available(iOS 14.0, *)
class KnobModel: ObservableObject {
    @Published var knobData: KnobData

    init() {
        if let data = UserDefaults.standard.data(forKey: "settings"),
            let decoded = try? JSONDecoder().decode(KnobData.self, from: data) {
            knobData = decoded
        } else {
            knobData = KnobData()
        }

    }

    func colorBinding(for keyPath: WritableKeyPath<KnobData, String>) -> Binding<Color> {
        return .init(
            get: { Color(UIColor(hex: self.knobData[keyPath: keyPath]) ?? .black) },
            set: { self.knobData[keyPath: keyPath] = $0.toHex() }
        )
    }
}

typealias ColorString = String

@available(iOS 14.0, *)
struct KnobData: Codable {
    var step: Int = 0

    var enableAnimation: Bool = true
    var animationDuration: Double = 0.3
    var animationEasing: String = "linear"

    var preferredWidth: Double = 400
    var backgroundColor: ColorString = Color.white.toHex()
    var cornerRadius: Double = 8

    var hidePointer: Bool = false
    var pointerBase: Double = 16
    var pointerLength: Double = 8
    var pointerCornerRadius: Double = 0

    var borderColor: ColorString = Color.accentColor.toHex()
    var borderWidth: Double = 0

    var shadowColor: ColorString = Color.black.opacity(0.5).toHex()
    var shadowRadius: Double = 14
    var shadowX: Double = 0
    var shadowY: Double = 3

    var keyholeShape: String = "rectangle"
    var keyholeSpread: Double = 0
    var keyholeCorner: Double = 4
    var keyholeBlur: Double = 0
    var backdropColor: ColorString = Color.black.opacity(0.3).toHex()

    var enableTarget: Bool = true
    var contentPreferredPosition: String = "bottom"
    var contentDistanceFromTarget: Double = 10
    var targetWidth: Double = 50
    var targetHeight: Double = 50
    var targetX: Double = -25
    var targetY: Double = 100
    var targetRelativeWidth: Double = 0
    var targetRelativeHeight: Double = 0
    var targetRelativeX: Double = 0.5
    var targetRelativeY: Double = 0
}

@available(iOS 15.0, *)
struct TooltipKnobs: View {
    @ObservedObject var model: KnobModel

    var body: some View {
        Form {
            Section("Content") {
                Picker("Step", selection: $model.knobData.step) {
                    Text("Text").tag(0)
                    Text("Background").tag(1)
                    Text("Lengthy").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section("Animation") {
                Toggle("Enable Animation", isOn: $model.knobData.enableAnimation)
                if model.knobData.enableAnimation {
                    Knob(label: "Duration", value: $model.knobData.animationDuration, range: 0...1)
                    Picker("Easing", selection: $model.knobData.animationEasing) {
                        Text("Linear").tag("linear")
                        Text("Ease In").tag("easeIn")
                        Text("Ease Out").tag("easeOut")
                        Text("Ease In Out").tag("easeInOut")
                    }
                }
            }

            Section("Tooltip") {
                Knob(label: "Preferred Width", value: $model.knobData.preferredWidth, range: 0...1000)
                ColorPicker("Background Color", selection: model.colorBinding(for: \.backgroundColor))
                Knob(label: "Corner Radius", value: $model.knobData.cornerRadius, range: 0...100)
            }
            Section("Tooltip Pointer") {
                Toggle("Hide Pointer", isOn: $model.knobData.hidePointer)
                Knob(label: "Pointer Base", value: $model.knobData.pointerBase, range: 0...200)
                Knob(label: "Pointer Length", value: $model.knobData.pointerLength, range: 0...200)
                Knob(label: "Pointer Corner Radius", value: $model.knobData.pointerCornerRadius, range: 0...100)
            }
            Section("Tooltip Border") {
                ColorPicker("Color", selection: model.colorBinding(for: \.borderColor))
                Knob(label: "Width", value: $model.knobData.borderWidth, range: 0...50)
            }
            Section("Tooltip Shadow") {
                ColorPicker("Color", selection: model.colorBinding(for: \.shadowColor))
                Knob(label: "Radius", value: $model.knobData.shadowRadius, range: 0...50)
                Knob(label: "X", value: $model.knobData.shadowX, range: 0...50)
                Knob(label: "Y", value: $model.knobData.shadowY, range: 0...50)
            }
            Section("Keyhole") {
                Picker("Shape", selection: $model.knobData.keyholeShape) {
                    Text("Rectangle").tag("rectangle")
                    Text("Circle").tag("circle")
                }
                Knob(label: "Spread", value: $model.knobData.keyholeSpread, range: -10...100)
                if model.knobData.keyholeShape == "rectangle" {
                    Knob(label: "Corner Radius", value: $model.knobData.keyholeCorner, range: .leastNonzeroMagnitude...100)
                } else if model.knobData.keyholeShape == "circle" {
                    Knob(label: "Blur Radius", value: $model.knobData.keyholeBlur, range: 0...500)
                }
                ColorPicker("Backdrop Color", selection: model.colorBinding(for: \.backdropColor))
            }
            Section("Target") {
                Toggle("Enable Target", isOn: $model.knobData.enableTarget)
                if model.knobData.enableTarget {
                    Picker("Content Preferred Position", selection: $model.knobData.contentPreferredPosition) {
                        Text("Top").tag("top")
                        Text("Bottom").tag("bottom")
                        Text("Left").tag("left")
                        Text("Right").tag("right")
                    }
                    Knob(label: "Content Distance From Target", value: $model.knobData.contentDistanceFromTarget, range: 0...100)
                    Knob(label: "Width", value: $model.knobData.targetWidth, range: 0...300)
                    Knob(label: "Height", value: $model.knobData.targetHeight, range: 0...300)
                    Knob(label: "X", value: $model.knobData.targetX, range: -1000...1000)
                    Knob(label: "Y", value: $model.knobData.targetY, range: -1000...1000)
                    Knob(label: "Relative Width", value: $model.knobData.targetRelativeWidth, range: 0...1)
                    Knob(label: "Relative Height", value: $model.knobData.targetRelativeHeight, range: 0...1)
                    Knob(label: "Relative X", value: $model.knobData.targetRelativeX, range: 0...1)
                    Knob(label: "Relative Y", value: $model.knobData.targetRelativeY, range: 0...1)
                }
            }
        }
    }
}

@available(iOS 13.0, *)
struct Knob: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Slider(value: value, in: range, step: range.upperBound == 1 ? 0.01 : 1) {
                Text(label)
            } minimumValueLabel: {
                Text("\(range.lowerBound, specifier: "%.0f")").font(.caption)
            } maximumValueLabel: {
                Text("\(range.upperBound, specifier: "%.0f")").font(.caption)
            }
            .frame(maxWidth: 250)
            if #available(iOS 15.0, *) {
                TextField(label, value: value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
        }
    }
}

@available(iOS 14.0, *)
extension Experience {
    static func tooltip(knobData: KnobData) -> Experience {
        let experienceString = #"""
        {
            "id": "5f1be737-1499-4aa0-9578-8b19a1ca952e",
            "name": "POC Modal Two",
            "type": "mobile",
            "tags": [],
            "theme": "",
            "actions": {},
            "traits": [],
            "steps": [
                {
                    "id": "13aa5509-7341-40ee-9db3-1f94a0c9f700",
                    "type": "group",
                    "actions": {},
                    "traits": [
                        {
                            "type": "@appcues/tooltip",
                            "config": {
                                "pointerBase": \#(knobData.pointerBase),
                                "pointerLength": \#(knobData.pointerLength),
                                "hidePointer": \#(knobData.hidePointer),
                                "style": {
                                    "width": \#(knobData.preferredWidth),
                                    "cornerRadius": \#(knobData.cornerRadius),
                                    "backgroundColor": { "light": "\#(knobData.backgroundColor)" },
                                    "shadow": {
                                        "color": { "light": "\#(knobData.shadowColor)" },
                                        "radius": \#(knobData.shadowRadius),
                                        "x": \#(knobData.shadowX),
                                        "y": \#(knobData.shadowY)
                                    },
                                    "borderColor": { "light": "\#(knobData.borderColor)" },
                                    "borderWidth": \#(knobData.borderWidth)
                                }
                            }
                        },
                        {
                            "type": "@appcues/skippable"
                        },
                        {
                            "type": "@appcues/backdrop",
                            "config": {
                                "backgroundColor": { "light": "\#(knobData.backdropColor)" }
                            }
                        },
                        {
                            "type": "@appcues/step-transition-animation",
                            "config": {
                            }
                        },
                        {
                            "type": "@appcues/backdrop-keyhole",
                            "config": {
                                "shape": "\#(knobData.keyholeShape)",
                                "cornerRadius": \#(knobData.keyholeCorner),
                                "blurRadius": \#(knobData.keyholeBlur),
                                "spreadRadius": \#(knobData.keyholeSpread)
                            }
                        },
                        {
                            "type": "@appcues/target-rectangle",
                            "config": {
                                "contentDistanceFromTarget": \#(knobData.contentDistanceFromTarget),
                                "contentPreferredPosition": "\#(knobData.contentPreferredPosition)",
                                "x": \#(knobData.targetX),
                                "y": \#(knobData.targetY),
                                "width": \#(knobData.targetWidth),
                                "height": \#(knobData.targetHeight),
                                "relativeX": \#(knobData.targetRelativeX),
                                "relativeY": \#(knobData.targetRelativeY),
                                "relativeWidth": \#(knobData.targetRelativeWidth),
                                "relativeHeight": \#(knobData.targetRelativeHeight)
                            }
                        }
                    ],
                    "children": [
                        {
                            "id": "c1fd299a-c6fb-4d22-8852-9de1fb582dcc",
                            "type": "modal",
                            "parentId": "13aa5509-7341-40ee-9db3-1f94a0c9f700",
                            "contentType": "application/json",
                            "content": {
                                "type": "stack",
                                "id": "2cf7dbf7-1234-4130-b642-85861f9c6b6a",
                                "orientation": "vertical",
                                "style": {},
                                "items": [
                                    {
                                        "type": "stack",
                                        "id": "1809a484-8810-49d3-ab92-7339be4c784f",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "text",
                                                "id": "e905d8bf-b1ad-4401-adfe-2f7e01878fa1",
                                                "content": {
                                                    "type": "text",
                                                    "id": "d52cd085-3f57-4218-8eb2-973f654a5dcf",
                                                    "text": "Shake to momentarily hide the tooltip knobs and see the whole screen.",
                                                    "style": {
                                                        "marginTop": 10,
                                                        "marginLeading": 10,
                                                        "marginBottom": 10,
                                                        "marginTrailing": 10,
                                                        "fontSize": 17,
                                                        "textAlignment": "center",
                                                        "foregroundColor": { "light": "#394455", "dark": "#ffffff" }
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                ]
                            },
                            "traits": [],
                            "actions": {}
                        },
                        {
                            "id": "3ec297e1-b921-46d0-b206-a0d8d678156d",
                            "type": "modal",
                            "parentId": "13aa5509-7341-40ee-9db3-1f94a0c9f700",
                            "contentType": "application/json",
                            "content": {
                                "type": "stack",
                                "id": "7f209a5d-992d-4363-9d84-0300ccee9894",
                                "orientation": "vertical",
                                "style": {},
                                "items": [
                                    {
                                        "id": "98a2a2c2-f6ca-41a3-9d31-7325801f40aa",
                                        "role": "row",
                                        "type": "stack",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "items": [
                                            {
                                                "blockType": "imageWithText",
                                                "content": {
                                                    "distribution": "center",
                                                    "id": "8e1a7a89-8d43-4d1c-ac2a-c64c4f05778c",
                                                    "items": [
                                                        {
                                                            "contentMode": "fit",
                                                            "id": "b1589804-5f67-468c-9c84-a08071c063c0",
                                                            "imageUrl": "https://res.cloudinary.com/dnjrorsut/image/upload/v1660836995/103523/roh2p8ba1mtwtzganmad.png",
                                                            "intrinsicSize": {
                                                                "height": 112,
                                                                "width": 112
                                                            },
                                                            "style": {
                                                                "marginTrailing": 8,
                                                                "verticalAlignment": "top",
                                                                "width": 56
                                                            },
                                                            "type": "image"
                                                        },
                                                        {
                                                            "id": "88e3ee02-7c4c-47b5-8de5-f937680171b1",
                                                            "items": [
                                                                {
                                                                    "id": "5b13d5ef-3be0-42d1-83a3-a23844f326fc",
                                                                    "style": {
                                                                        "fontName": "System Default Semibold",
                                                                        "foregroundColor": {
                                                                            "light": "#000000"
                                                                        },
                                                                        "horizontalAlignment": "leading",
                                                                        "textAlignment": "leading"
                                                                    },
                                                                    "text": "New feature",
                                                                    "type": "text"
                                                                },
                                                                {
                                                                    "id": "c54373f1-0e84-4044-9122-ef21d1032d50",
                                                                    "style": {
                                                                        "foregroundColor": {
                                                                            "light": "#000000"
                                                                        },
                                                                        "horizontalAlignment": "leading",
                                                                        "textAlignment": "leading"
                                                                    },
                                                                    "text": "Now you can customize your experience!",
                                                                    "type": "text"
                                                                }
                                                            ],
                                                            "orientation": "vertical",
                                                            "style": {
                                                                "horizontalAlignment": "leading"
                                                            },
                                                            "type": "stack"
                                                        }
                                                    ],
                                                    "orientation": "horizontal",
                                                    "style": {
                                                        "horizontalAlignment": "leading",
                                                        "paddingBottom": 8,
                                                        "paddingLeading": 8,
                                                        "paddingTop": 8,
                                                        "paddingTrailing": 8,
                                                        "verticalAlignment": "top"
                                                    },
                                                    "type": "stack"
                                                },
                                                "id": "b147990e-d250-454d-85d8-064cdc78e1f2",
                                                "type": "block"
                                            }
                                        ]
                                    }
                                ]
                            },
                            "traits": [
                                {
                                    "type": "@appcues/background-content",
                                    "config": {
                                        "content": {
                                            "type": "image",
                                            "id": "acdd9c27-6c8f-4660-9c59-69cc4bd0955c",
                                            "imageUrl": "https://res.cloudinary.com/dnjrorsut/image/upload/v1662654207/mobile-builder/spacer.gif",
                                            "style": {
                                                "backgroundImage": {
                                                    "imageUrl": "https://res.cloudinary.com/dnjrorsut/image/upload/v1659625079/103523/eeccq20y08ltwxrys1vr.jpg",
                                                    "contentMode": "fill",
                                                    "intrinsicSize": {
                                                        "width": 2113,
                                                        "height": 3360
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            ],
                            "actions": {}
                        },
                        {
                            "id": "e3f83087-11ed-4ae6-95c5-867917e3eb7a",
                            "type": "modal",
                            "parentId": "13aa5509-7341-40ee-9db3-1f94a0c9f700",
                            "contentType": "application/json",
                            "content": {
                                "type": "stack",
                                "orientation": "vertical",
                                "id": "fca5a243-8eda-470e-b935-590e3cb88d7b",
                                "style": {},
                                "items": [
                                    {
                                        "type": "block",
                                        "blockType": "hero",
                                        "id": "dd3f9656-51bc-4607-a6ab-36473eb8b25e",
                                        "content": {
                                            "type": "stack",
                                            "id": "c6931c58-2ee6-4fb5-98f8-240c186ec2df",
                                            "orientation": "vertical",
                                            "style": {
                                                "backgroundColor": { "light": "#5C5CFF" },
                                                "backgroundImage": {
                                                    "imageUrl": "https://res.cloudinary.com/dnjrorsut/image/upload/v1657809085/mobile-builder/default-image.jpg",
                                                    "contentMode": "fill"
                                                },
                                                "width": -1
                                            },
                                            "items": [
                                                {
                                                    "type": "stack",
                                                    "id": "105156f6-7521-4172-940a-604442ec4def",
                                                    "orientation": "horizontal",
                                                    "distribution": "equal",
                                                    "items": [
                                                        {
                                                            "type": "text",
                                                            "id": "2e59ef0f-4737-4025-8465-bbfab58123eb",
                                                            "text": "Ready to make your workflow simpler?",
                                                            "style": {
                                                                "marginTop": 30,
                                                                "marginBottom": 15,
                                                                "marginLeading": 15,
                                                                "marginTrailing": 15,
                                                                "fontName": "System Default Light",
                                                                "fontSize": 28,
                                                                "textAlignment": "center",
                                                                "foregroundColor": { "light": "#ffffff" }
                                                            }
                                                        }
                                                    ]
                                                },
                                                {
                                                    "type": "stack",
                                                    "id": "4b9c9252-7aa7-4567-82a4-cc28b3409174",
                                                    "orientation": "horizontal",
                                                    "distribution": "equal",
                                                    "items": [
                                                        {
                                                            "type": "text",
                                                            "id": "e37e82a5-e1b6-4be4-9714-158e224ed43a",
                                                            "text": "Take a few moments to learn how to best use our features.",
                                                            "style": {
                                                                "fontSize": 22,
                                                                "fontName": "System Default Semibold",
                                                                "textAlignment": "center",
                                                                "foregroundColor": { "light": "#ffffff" },
                                                                "marginBottom": 30,
                                                                "marginLeading": 15,
                                                                "marginTrailing": 15
                                                            }
                                                        }
                                                    ]
                                                }
                                            ]
                                        }
                                    },
                                    {
                                        "type": "stack",
                                        "id": "f568bf70-c599-4818-8958-05475bf37352",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "text",
                                                "id": "91443351-cdef-4d63-a034-0a1a82500413",
                                                "content": {
                                                    "type": "text",
                                                    "id": "486cd991-4b02-4fa6-b737-bf3bf039b0c5",
                                                    "text": "Ready to make your workflow simpler?",
                                                    "style": {
                                                        "marginTop": 15,
                                                        "marginBottom": 15,
                                                        "fontName": "System Default Bold",
                                                        "fontSize": 22,
                                                        "textAlignment": "center",
                                                        "lineHeight": 24,
                                                        "foregroundColor": { "light": "#000000", "dark": "#ffffff" }
                                                    }
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "type": "stack",
                                        "id": "1b5d3cee-341d-4e6d-8691-ba947bb3a805",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "text",
                                                "id": "3fcd7b90-9905-4a66-938a-7768b35f57d1",
                                                "content": {
                                                    "type": "text",
                                                    "id": "4693cb43-669d-4d03-9ae3-55879905f529",
                                                    "text": "Take a few moments to learn how to best use our features.",
                                                    "style": {
                                                        "marginBottom": 15,
                                                        "marginLeading": 15,
                                                        "marginTrailing": 15,
                                                        "fontSize": 17,
                                                        "textAlignment": "center",
                                                        "foregroundColor": { "light": "#000000", "dark": "#ffffff" }
                                                    }
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        "type": "stack",
                                        "id": "154e2661-8c40-4236-a2b3-e9e12a4d824b",
                                        "orientation": "horizontal",
                                        "distribution": "equal",
                                        "style": {},
                                        "items": [
                                            {
                                                "type": "block",
                                                "blockType": "button",
                                                "id": "96d0e52f-c46f-4f92-ae1a-2d40bbf3b607",
                                                "content": {
                                                    "type": "button",
                                                    "id": "b947f397-80bd-4dc2-8264-850333609558",
                                                    "content": {
                                                        "type": "text",
                                                        "id": "00591d74-20b6-4377-af5f-c67571d67e27",
                                                        "text": "Next",
                                                        "style": {
                                                            "fontSize": 17,
                                                            "foregroundColor": { "light": "#ffffff" }
                                                        }
                                                    },
                                                    "style": {
                                                        "marginBottom": 16,
                                                        "paddingTop": 12,
                                                        "paddingLeading": 24,
                                                        "paddingBottom": 12,
                                                        "paddingTrailing": 24,
                                                        "backgroundColor": { "light": "#5C5CFF" },
                                                        "cornerRadius": 6
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                ]
                            },
                            "traits": [],
                            "actions": {}
                        }
                    ]
                }
            ]
        }
        """#

        let data = experienceString.data(using: .utf8)!

        return try! JSONDecoder().decode(Experience.self, from: data)
    }
}

@available(iOS 14.0, *)
extension Color {
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
