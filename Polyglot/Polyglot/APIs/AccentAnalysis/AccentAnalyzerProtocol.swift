//
//  File.swift
//  Polyglot
//
//  Created by Ho on 8/29/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

protocol AccentAnalyzerProtocol {
    
    static var shared: AccentAnalyzerProtocol { get }
    
    func analyze(for text: String, completion: @escaping ([Token]) -> Void)
    
}

var word2langForAccentAnalysis: [String: LangCode] = [:]
func analyzeAccents(for text: String, completion: @escaping ([Token]) -> Void) {
    
    word2langForAccentAnalysis[text] = LangCode.currentLanguage
    LangCode.currentLanguage.accentAnalyzer?.analyze(for: text) { tokens in
        guard LangCode.currentLanguage == word2langForAccentAnalysis[text] else {
            return
        }
        word2langForAccentAnalysis.removeValue(forKey: text)
        completion(tokens)
    }

}

func addAccentMarks(for text: String, with tokens: [Token]) -> String {
    
    var s = text
    var curIndexInS: Int = 0
    var tokenIndex: Int = 0
    while tokenIndex < tokens.count {
        let token = tokens[tokenIndex]
        
        // Move to tokens[tokenIndex] in s.
        while !s.lowercased().substring(from: curIndexInS).starts(with: token.text.lowercased()) {
            curIndexInS += 1
            if curIndexInS >= s.count {  // The condition is true when some tokens in a word are missing.
                return text
            }
        }
        
        // Insert an accent mark.
        if let accentLoc = token.accentLoc {
            s.insert(
                Token.accentSymbol,
                at: s.index(
                    s.startIndex,
                    offsetBy: curIndexInS + accentLoc + 1
                )
            )
            curIndexInS += token.text.count
        }
        // Move on.
        tokenIndex += 1
    }
    
    return s
    
}
