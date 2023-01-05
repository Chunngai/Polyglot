//
//  UISearchBarExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

extension UISearchBar {
    var keyWord: String? {
        self.text?.strip()
    }
}
