//
//  ReusableView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol ReusableView {
    static var reuseID: String { get }
}

extension ReusableView {
    static var reuseID: String { String(describing: self) }
}

extension UICollectionReusableView: ReusableView {}
extension UITableViewCell: ReusableView {}
extension UITableViewHeaderFooterView: ReusableView {}
