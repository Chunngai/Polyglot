//
//  UITableViewExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    
    func removeRedundantSeparators() {
        // https://stackoverflow.com/questions/14460772/hide-remove-separator-line-if-uitableviewcells-are-empty
        tableFooterView = UIView()
    }
    
}
