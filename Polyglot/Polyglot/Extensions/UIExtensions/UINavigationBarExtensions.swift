//
//  UINavigationBar.swift
//  Polyglot
//
//  Created by Sola on 2022/12/20.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationBar {
    func hideBarSeparator() {
        // https://stackoverflow.com/questions/26390072/how-to-remove-border-of-the-navigationbar-in-swift
        
        setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        shadowImage = UIImage()
    }
    
    func showBarSeparator() {
        // https://stackoverflow.com/questions/26390072/how-to-remove-border-of-the-navigationbar-in-swift
        
        setBackgroundImage(nil, for: UIBarMetrics.default)
        shadowImage = nil
    }
}
