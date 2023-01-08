//
//  UIntExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

extension UInt {
    
    static func random(from probabilities: [Double]) -> UInt {

        // https://stackoverflow.com/questions/30309556/generate-random-numbers-with-a-given-distribution
        
        // Sum of all probabilities (so that we don't have to require that the sum is 1.0).
        let sum = probabilities.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum.
        let rnd = Double.random(in: 0.0 ..< sum)
        // Find the first interval of accumulated probabilities into which `rnd` falls.
        var accum = 0.0
        for (i, p) in probabilities.enumerated() {
            accum += p
            if rnd < accum {
                return UInt(i)
            }
        }
        // This point might be reached due to floating point inaccuracies.
        return UInt((probabilities.count - 1))
    }
    
}
