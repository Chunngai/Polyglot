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
}

extension String {
    
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
    
    func normalizeQuotes() -> String {
        return self
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
    }
    
    func normalized(shouldStrip: Bool = true, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> String {
        var normalizedString = self
        
        if shouldStrip {
            normalizedString = normalizedString.strip()
        }
        
        normalizedString = normalizedString
            .replaceMultipleSpacesWithSingleOne()
            .normalizeQuotes()
        
        // https://stackoverflow.com/questions/36727310/is-there-a-way-to-convert-special-characters-to-normal-characters-in-swift
        if caseInsensitive {
            normalizedString = normalizedString.folding(options: [.caseInsensitive], locale: nil)
        }
        if diacriticInsensitive {
            normalizedString = normalizedString.folding(options: [.diacriticInsensitive], locale: nil)
        }
        
        return normalizedString
    }
}

extension String {
    
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
    
    func tokenized(with tokenizer: NLTokenizer) -> [String] {
        
//        let stringToTokenize = self
//            // If the string starts with 「,
//            // the tokenization does not work properly (returns an empty list).
//            // Therefore, preprocess the string before the tokenization.
//            .replacingOccurrences(of: "「", with: "")
//            .replacingOccurrences(of: "」", with: "")
        let stringToTokenize = self
        tokenizer.string = stringToTokenize
        
        var components: [String] = []
        tokenizer.enumerateTokens(in: stringToTokenize.startIndex..<stringToTokenize.endIndex) { (range, attributes) -> Bool in
            components.append(String(stringToTokenize[range]))
            return true
        }

        return components
    }
    
}

extension String {
    
    var isNumericText: Bool {
        
        return Int(self) != nil || Float(self) != nil || Double(self) != nil || self.allSatisfy({ char in  // https://sarunw.com/posts/how-to-check-if-string-is-number-in-swift/
            char.isNumber || char == "." || char == ","
        }) || LangCode.currentLanguage.numberFormatter.number(from: self.lowercased())?.stringValue != nil
        
    }
    
}
