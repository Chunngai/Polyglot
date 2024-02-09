//
//  CFStringExtensions.swift
//  Polyglot
//
//  Created by Ho on 2/9/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

extension CFString {
    
    func subString(with range: CFRange) -> CFString {
        guard let substring = CFStringCreateWithSubstring(kCFAllocatorDefault, self, range) else {
            return "" as CFString
        }
        return substring as String as CFString
    }
    
}
