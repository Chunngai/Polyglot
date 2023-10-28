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
    
    func normalizeQuotes() -> String {
        return self
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
    }
    
    func removePunctuation() -> String {
                
        // Define a character set for punctuation characters, considering multiple languages.
        let punctuationCharacterSet = NSMutableCharacterSet()
        punctuationCharacterSet.formUnion(with: .punctuationCharacters)
        
        // Create a mutable string to remove punctuation.
        let modifiedString = NSMutableString(string: self)
        
        // Enumerate and remove punctuation characters.
        var range = modifiedString.rangeOfCharacter(from: punctuationCharacterSet as CharacterSet)
        while range.location != NSNotFound {
            modifiedString.deleteCharacters(in: range)
            range = modifiedString.rangeOfCharacter(from: punctuationCharacterSet as CharacterSet)
        }
        
        // Convert the modified string back to a Swift String.
        return String(modifiedString)
    }
}

extension String {
    
    func textSize(withFont font: UIFont) -> CGSize {
        return self.size(withAttributes: [NSAttributedString.Key.font : font])
    }
}

extension String {
    
    func normalized(caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> String {
        var normalizedString = self
            .strip()
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
    
    func components(from tokenizer: NLTokenizer) -> [String] {
        
        let stringToTokenize = self
            // If the string starts with 「,
            // the tokenization does not work properly (returns an empty list).
            // Therefore, preprocess the string before the tokenization.
            .replacingOccurrences(of: "「", with: "")
            .replacingOccurrences(of: "」", with: "")
        tokenizer.string = stringToTokenize
        
        var components: [String] = []
        tokenizer.enumerateTokens(in: stringToTokenize.startIndex..<stringToTokenize.endIndex) { (range, attributes) -> Bool in
            components.append(String(stringToTokenize[range]))
            return true
        }
//        print(components)
        return components
    }
    
}
