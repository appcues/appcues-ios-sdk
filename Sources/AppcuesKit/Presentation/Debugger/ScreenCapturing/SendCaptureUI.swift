//
//  SendCaptureUI.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/13/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

/// Namespaced Views used in the screen capture confirmation dialog.
@available(iOS 13.0, *)
internal enum SendCaptureUI {

    internal enum SendCaptureError: Error {
        case canceled
    }

    struct ConfirmationDialogView: View {

        let capture: Capture
        let completion: (Result<String, Error>) -> Void

        let helpLinkURL = URL(string: "https://docs.appcues.com/mobile-sdk-screen-capture-help")

        @State var screenName = ""

        var body: some View {
            VStack(spacing: 16) {
                header
                screenshotImage
                captureInfo
                nameInput
                bottomButtons
            }
            .padding(25)
            .frame(maxWidth: .infinity)
        }

        @ViewBuilder var header: some View {
            HStack {
                Text("Send screen capture")
                    .font(.system(size: 20, weight: .regular))
                Spacer()
                Button {
                    completion(.failure(SendCaptureError.canceled))
                } label: {
                    Image(systemName: "xmark").foregroundColor(.primary)
                }
            }
        }

        @ViewBuilder var screenshotImage: some View {
            Image(uiImage: capture.annotatedScreenshot)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 375)
                .overlay(Rectangle().stroke(Color.appcuesImageBorder, lineWidth: 1))
        }

        @ViewBuilder var captureInfo: some View {
            // The Link view is iOS 14+
            if let helpLinkURL = helpLinkURL, #available(iOS 14.0, *) {
                VStack(alignment: .leading, spacing: 8) {
                    if capture.targetableElementCount > 0 {
                        Text("Not seeing the element you want highlighted?")
                    } else {
                        Text("Warning: this screen capture does not have any targetable elements identified.")
                            .foregroundColor(Color.orange)
                    }
                    Link(destination: helpLinkURL) {
                        Text("Tap to view troubleshooting documentation.")
                    }
                    .foregroundColor(.blue)
                }
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        @ViewBuilder var nameInput: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.system(size: 12))
                    .foregroundColor(.appcuesBlurple)
                MultilineTextView(
                    text: $screenName,
                    model: TextInputStyle(numberOfLines: 1, font: UIFont.systemFont(ofSize: 16))
                )
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.appcuesTextInputBorder, lineWidth: 1)
                    )
            }
        }

        @ViewBuilder var bottomButtons: some View {
            HStack {
                Button {
                    completion(.failure(SendCaptureError.canceled))
                } label: {
                    Text("Retry").font(.system(size: 14)).foregroundColor(.appcuesBlurple)
                }
                .frame(height: 40)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .overlay(RoundedRectangle(cornerRadius: 6.0).stroke(Color.appcuesBlurple, lineWidth: 1))

                Spacer()

                Button {
                    completion(.success(screenName))
                } label: {
                    Text("Send to builder").font(.system(size: 14)).foregroundColor(.white)
                }
                .frame(height: 40)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.appcuesBlurple, .appcuesBlurpleGradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(screenName.isEmpty ? 0.5 : 1.0)
                )
                .cornerRadius(6.0)
                .disabled(screenName.isEmpty)
            }
        }
    }
}

@available(iOS 13.0, *)
extension Color {
    // attempted to put colors in asset catalog and use SwiftGen, but the new 6.6.2 version has an
    // open issue with the generated code https://github.com/SwiftGen/SwiftGen/issues/1022 related
    // to SwiftUI colors on XCode 14+
    static let appcuesImageBorder = Color(red: 220 / 255, green: 228 / 255, blue: 242 / 255)
    static let appcuesBlurple = Color(red: 92 / 255, green: 92 / 255, blue: 255 / 255)
    static let appcuesBlurpleGradientEnd = Color(red: 125 / 255, green: 82 / 255, blue: 255 / 255)
    static let appcuesTextInputBorder = Color(red: 121 / 255, green: 116 / 255, blue: 126 / 255)
}
