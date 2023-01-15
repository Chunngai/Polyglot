//
//  ArrayExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/15.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        // https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
        
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
