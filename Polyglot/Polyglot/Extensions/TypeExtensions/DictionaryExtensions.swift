//
//  DictionaryExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/6.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func setDefault(value: Value, for key: Key) {
        
        // https://stackoverflow.com/questions/56071744/swift-equivalent-of-python-dictionary-setdefault-method
        
        if !keys.contains(key) {
            self[key] = value
        }
    }
}
