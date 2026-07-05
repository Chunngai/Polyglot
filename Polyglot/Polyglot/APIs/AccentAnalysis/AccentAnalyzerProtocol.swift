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
    
    func analyze(
        for text: String,
        completion: @escaping (
            [Token],
            String?  // Fixed text. E.g., text after replacing je to jo for Russian.
        ) -> Void
    )
    
}

var word2langForAccentAnalysis: [String: LangCode] = [:]
func analyzeAccents(for text: String, completion: @escaping (
    [Token],  // tokens.
    String?,  // Fixed text.
    String  // Analysis query.
) -> Void) {
    
    word2langForAccentAnalysis[text] = LangCode.currentLanguage
    LangCode.currentLanguage.accentAnalyzer?.analyze(for: text) { tokens, fixedText in
        guard LangCode.currentLanguage == word2langForAccentAnalysis[text] else {
            return
        }
        // TODO: -  The following commented code leads to crash.
//        if word2langForAccentAnalysis.keys.contains(text) {
//            word2langForAccentAnalysis.removeValue(forKey: text)
//        }
        completion(
            tokens,
            fixedText,
            text
        )
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

func calculateAccentLocs(for text: String, with tokens: [Token]) -> [Int] {

    // Modified from addAccentMarks(for text: String, with tokens: [Token]) -> String.

    var accentLocs: [Int] = []
    var curIndexInText: Int = 0
    var tokenIndex: Int = 0
    while tokenIndex < tokens.count {
        let token = tokens[tokenIndex]

        // Move to tokens[tokenIndex] in s.
        while !text.lowercased().substring(from: curIndexInText).starts(with: token.text.lowercased()) {
            curIndexInText += 1
            if curIndexInText >= text.count {  // The condition is true when some tokens in a word are missing.
                return []
            }
        }

        // Insert an accent mark.
        if let accentLoc = token.accentLoc {
            accentLocs.append(curIndexInText + accentLoc)  // Different here.
            curIndexInText += token.text.count
        }
        // Move on.
        tokenIndex += 1
    }

    return accentLocs

}

func calculateVerbAspectAnnotations(for text: String, with tokens: [Token]) -> [VerbAspectAnnotation] {
    var annotations: [VerbAspectAnnotation] = []
    var curIndexInText = 0
    for token in tokens {
        while !text.lowercased().substring(from: curIndexInText).starts(with: token.text.lowercased()) {
            curIndexInText += 1
            if curIndexInText >= text.count { return annotations }
        }
        if let aspect = token.aspect {
            let label: String?
            switch aspect {
            case "imperfective": label = "(imp.)"
            case "perfective":   label = "(p.)"
            case "both":         label = "(bi.)"
            default:             label = nil
            }
            if let label = label {
                annotations.append(VerbAspectAnnotation(
                    position: curIndexInText,
                    length: token.text.count,
                    label: label
                ))
            }
        }
        curIndexInText += token.text.count
    }
    return annotations
}

// Maps prepositions to the case they govern.
// в/на govern both acc and prep, but an ambiguous token after в/на is almost
// certainly not in acc (acc forms are usually unambiguous), so we map to prep.
private let prepToCase: [String: String] = [
    // Genitive
    "без": "gen", "до": "gen", "из": "gen", "от": "gen", "у": "gen",
    "для": "gen", "после": "gen", "вместо": "gen", "кроме": "gen",
    "около": "gen", "вдоль": "gen", "возле": "gen", "против": "gen",
    "среди": "gen", "мимо": "gen", "вокруг": "gen", "ради": "gen",
    "вне": "gen", "внутри": "gen", "из-за": "gen", "из-под": "gen",
    // Dative
    "к": "dat", "ко": "dat", "благодаря": "dat", "вопреки": "dat",
    "согласно": "dat", "навстречу": "dat", "наперекор": "dat",
    // Accusative
    "через": "acc", "про": "acc", "сквозь": "acc",
    // Instrumental
    "над": "inst", "перед": "inst", "между": "inst",
    // Prepositional
    "в": "prep", "на": "prep",
    "о": "prep", "об": "prep", "обо": "prep", "при": "prep",
    "во": "prep",
]

func calculateNounCaseAnnotations(for text: String, with tokens: [Token]) -> [NounCaseAnnotation] {
    var annotations: [NounCaseAnnotation] = []
    var curIndexInText = 0
    for (i, token) in tokens.enumerated() {
        while !text.lowercased().substring(from: curIndexInText).starts(with: token.text.lowercased()) {
            curIndexInText += 1
            if curIndexInText >= text.count { return annotations }
        }
        if var nounCase = token.nounCase {
            if nounCase == "ambiguous" {
                let prevText = i > 0 ? tokens[i - 1].text.lowercased() : ""
                if let resolved = prepToCase[prevText] {
                    nounCase = resolved
                }
            }
            annotations.append(NounCaseAnnotation(
                position: curIndexInText,
                length: token.text.count,
                label: nounCase
            ))
        }
        curIndexInText += token.text.count
    }
    return annotations
}
