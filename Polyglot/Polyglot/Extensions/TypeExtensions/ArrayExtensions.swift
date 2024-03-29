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
    
    func randomElements(of number: Int) -> [Element] {
      
        guard self.count >= number else {
            return self
        }

        // Enumerate the array and shuffle the resulting pairs
        let shuffledPairs = self.enumerated().shuffled()

        // Take the first 10 pairs, sort them by their original indices to maintain order
        let selectedPairs = shuffledPairs.prefix(number).sorted { $0.offset < $1.offset }

        // Map the result back to just the elements
        let selectedElements = selectedPairs.map { $0.element }
        return selectedElements
    }
    
    func chunked(into size: Int) -> [[Element]] {
        // https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
        
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array where Iterator.Element == Double {
    
    func toPositives() -> [Double]? {
        guard !self.isEmpty else {
            return nil
        }
        
        var minVal = self.min()!
        if minVal > 0 {
            return self
        } else {
            minVal = abs(minVal) + 1  // If minVal == 0, minVal will become 1.
            return self.map { (val) -> Double in
                val + minVal
            }
        }
    }
}
