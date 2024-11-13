//
//  UIScrollViewExtensions.swift
//  Polyglot
//
//  Created by Ho on 11/13/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
    
    func scrollTo(
        contentOffset: CGPoint,
        minOffsetX: CGFloat? = nil,
        minOffsetY: CGFloat? = nil,
        maxOffsetX: CGFloat? = nil,
        maxOffsetY: CGFloat? = nil,
        animated: Bool
    ) {
        
        var contentOffset = contentOffset
        
        if let minOffsetX = minOffsetX, contentOffset.x < minOffsetX {
            contentOffset.x = minOffsetX
        }
        if let minOffsetY = minOffsetY, contentOffset.y < minOffsetY {
            contentOffset.y = minOffsetY
        }
        
        if let maxOffsetX = maxOffsetX, contentOffset.x > maxOffsetX {
            contentOffset.x = maxOffsetX
        }
        if let maxOffsetY = maxOffsetY, contentOffset.y > maxOffsetY {
            contentOffset.y = maxOffsetY
        }
        
        setContentOffset(
            contentOffset,
            animated: animated
        )
        
    }
    
}
