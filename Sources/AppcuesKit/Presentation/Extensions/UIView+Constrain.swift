//
//  DebugView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIView {

     func pin(to view: UIView, margins: NSDirectionalEdgeInsets = .zero) {
        self.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor, constant: margins.top),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margins.leading),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1.0 * margins.trailing),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1.0 * margins.bottom)
        ])
    }

    func pin(to guide: UILayoutGuide) {
       self.translatesAutoresizingMaskIntoConstraints = false

       NSLayoutConstraint.activate([
           self.topAnchor.constraint(equalTo: guide.topAnchor),
           self.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
           self.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
           self.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
       ])
   }

    func center(in view: UIView) {
       self.translatesAutoresizingMaskIntoConstraints = false

       NSLayoutConstraint.activate([
           self.centerXAnchor.constraint(equalTo: view.centerXAnchor),
           self.centerYAnchor.constraint(equalTo: view.centerYAnchor)
       ])
   }

}
