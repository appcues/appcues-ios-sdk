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

        @State var screenName = ""

        var body: some View {
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    header
                    screenshotImage
                    nameInput
                    bottomButtons
                }
                .padding(25)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(6.0)

                Spacer()
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.33).edgesIgnoringSafeArea(.all))
        }

        @ViewBuilder var header: some View {
            HStack {
                Text("Send screen capture")
                    .font(.system(size: 20, weight: .regular))
                Spacer()
                Button {
                    completion(.failure(SendCaptureError.canceled))
                } label: {
                    Image(systemName: "xmark").foregroundColor(.black)
                }
            }
        }

        @ViewBuilder var screenshotImage: some View {
            Image(uiImage: capture.screenshot)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 375)
                .overlay(Rectangle().stroke(Color.appcuesImageBorder, lineWidth: 1))
        }

        @ViewBuilder var nameInput: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.system(size: 12))
                    .foregroundColor(.appcuesBlurple)
                TextField("Name", text: $screenName)
                    .font(.system(size: 16))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
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
                .background(LinearGradient(gradient: Gradient(colors: [.appcuesBlurple, .appcuesBlurpleGradientEnd]),
                                           startPoint: .leading,
                                           endPoint: .trailing).opacity(screenName.isEmpty ? 0.5 : 1.0))
                .cornerRadius(6.0)
                .disabled(screenName.isEmpty)
            }
        }
    }

    struct CaptureSuccessToastView: View {

        let screenName: String

        var body: some View {
            VStack {
                toastMessage
                    .lineSpacing(7)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue)
                    .cornerRadius(6)
            }
            .padding(25)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        @ViewBuilder var toastMessage: Text {
            Text("\"\(screenName)\"").font(.system(size: 14, weight: .bold ))
            +
            Text(" is now available for preview and targeting.").font(.system(size: 14))
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
