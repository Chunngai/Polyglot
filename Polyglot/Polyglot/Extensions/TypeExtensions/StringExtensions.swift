//
//  StringExt.swift
//  Polyglot
//
//  Created by Sola on 2022/12/25.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

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
}

extension String {
    
    // TODO: - Improve the code here.
    
    var normalized: String {
        var s = self.strip()
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)  // https://stackoverflow.com/questions/36727310/is-there-a-way-to-convert-special-characters-to-normal-characters-in-swift
        
        if Variables.lang == LangCodes.ja {
            s = s.replacingOccurrences(of: " ", with: "")
        } else if Variables.lang == LangCodes.en || Variables.lang == LangCodes.es {
            s = s.replaceMultipleSpacesWithSingleOne()
        }
        
        return s
    }
    
    var components: [String] {
        var s: String = self
        for punct in ",.-'" {  // TODO: - Handle other punctuations.
            s = s.replacingOccurrences(of: String(punct), with: "")
        }
        
        if Variables.lang == LangCodes.ja {
            return s.map( {String($0)} )
        } else if Variables.lang == LangCodes.en || Variables.lang == LangCodes.es {
            return s.split(with: " ")
        } else {
            return [s]
        }
    }
    
}
