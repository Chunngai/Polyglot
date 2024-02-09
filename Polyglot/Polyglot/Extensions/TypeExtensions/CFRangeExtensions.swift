//
//  CFRangeExtensions.swift
//  Polyglot
//
//  Created by Ho on 2/9/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

extension CFRange {
    var maxPosition: CFIndex {
        return location + length
    }
}
