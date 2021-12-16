//
//  DebugView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIView {

     func pin(to view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
