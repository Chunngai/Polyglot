//
//  StringExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation
import UIKit
import NaturalLanguage

extension String {
    func strip() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    func split(with separator: String) -> [String] {
        // https://stackoverflow.com/questions/49472570/in-swift-can-you-split-a-string-by-another-string-not-just-a-character
        return self.components(separatedBy: separator)  // Split by a string.
    }
    
    func replaceMultipleBlankLinesWithSingleLine() -> String {
        // https://stackoverflow.com/questions/47796228/remove-whitespace-and-multiple-line-from-string
        self.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
    }
    
    func replaceMultipleSpacesWithSingleOne() -> String {
        // https://stackoverflow.com/questions/36363415/replace-sequence-of-spaces-in-string-with-a-single-character-in-swift
        return self.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    func normalizeBlankLines() -> String {
        // E.g., " \n" -> "\n".
        self.replacingOccurrences(of: "\\s*?\\n", with: "\n", options: .regularExpression)
    }
    
    func nsrange(from range : Range<String.Index>) -> NSRange {
        // https://www.jianshu.com/p/beb4e463e6da
        return NSRange(range, in: self)
    }
}

extension String {
    
    func textSize(withFont font: UIFont) -> CGSize {
        return self.size(withAttributes: [NSAttributedString.Key.font : font])
    }
}

extension String {
    
    static let normalizationOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
    var normalized: String {
        return self
            .strip()
            // https://stackoverflow.com/questions/36727310/is-there-a-way-to-convert-special-characters-to-normal-characters-in-swift
            .folding(options: String.normalizationOptions, locale: nil)
    }
    
    func components(from tokenizer: NLTokenizer) -> [String] {
        
        tokenizer.string = self
        
        var components: [String] = []
        tokenizer.enumerateTokens(in: self.startIndex..<self.endIndex) { (range, attributes) -> Bool in
            components.append(String(self[range]))
            return true
        }
//        print(components)
        return components
    }
    
}
