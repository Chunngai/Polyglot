//
//  ArrayExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/15.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

extension Array {
    
        
    func randomElement(from probabilities: [Double]) -> Element? {

        guard !self.isEmpty else {
            return nil
        }
        guard self.count == probabilities.count else {
            return nil
        }
        
        // https://stackoverflow.com/questions/30309556/generate-random-numbers-with-a-given-distribution
        
        // Sum of all probabilities (so that we don't have to require that the sum is 1.0).
        let sum = probabilities.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum.
        let rnd = Double.random(in: 0.0 ..< sum)
        // Find the first interval of accumulated probabilities into which `rnd` falls.
        var accum = 0.0
        for (element, p) in zip(self, probabilities) {
            accum += p
            if rnd < accum {
                return element
            }
        }
        // This point might be reached due to floating point inaccuracies.
        return self.last!
    }
    
    func chunked(into size: Int) -> [[Element]] {
        // https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
        
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
