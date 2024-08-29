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
    
    func analyze(for word: Word, completion: @escaping ([Token]) -> Void)
    
}

var word2langForAccentAnalysis: [String: LangCode] = [:]
func analyzeAccents(for word: Word, completion: @escaping ([Token]) -> Void) {
    
    if LangCode.currentLanguage == LangCode.ja {
        var shouldUpdateAccent: Bool = false
        if word.tokens == nil {
            shouldUpdateAccent = true
        }
        if let accentAnalyzer = LangCode.currentLanguage.accentAnalyzer as? JapaneseAccentAnalyzer,
            accentAnalyzer.isOldAccents(word) {
            shouldUpdateAccent = true
        }
        guard shouldUpdateAccent else {
            return
        }
    }
    
    if LangCode.currentLanguage == LangCode.ru  {
        guard word.tokens == nil else {
            return
        }
    }
    
    word2langForAccentAnalysis[word.text] = LangCode.currentLanguage
    LangCode.currentLanguage.accentAnalyzer?.analyze(for: word) { tokens in
        guard LangCode.currentLanguage == word2langForAccentAnalysis[word.text] else {
            return
        }
        word2langForAccentAnalysis.removeValue(forKey: word.text)
        completion(tokens)
    }

}
