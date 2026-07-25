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
            case "ambiguous":    label = "(?)"
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

private let prepToCase: [String: Set<String>] = [
    // Genitive
    "без": ["gen"], "до": ["gen"], "из": ["gen"], "от": ["gen"], "у": ["gen"],
    "для": ["gen"], "после": ["gen"], "вместо": ["gen"], "кроме": ["gen"],
    "около": ["gen"], "вдоль": ["gen"], "возле": ["gen"], "против": ["gen"],
    "среди": ["gen"], "мимо": ["gen"], "вокруг": ["gen"], "ради": ["gen"],
    "вне": ["gen"], "внутри": ["gen"], "из-за": ["gen"], "из-под": ["gen"],
    // Dative
    "к": ["dat"], "ко": ["dat"], "благодаря": ["dat"], "вопреки": ["dat"],
    "согласно": ["dat"], "навстречу": ["dat"], "наперекор": ["dat"],
    // Accusative
    "через": ["acc"], "про": ["acc"], "сквозь": ["acc"],
    // Instrumental / ambiguous with genitive or accusative depending on meaning
    "над": ["inst"], "перед": ["inst"],
    "между": ["gen", "inst"],
    "с": ["gen", "inst"],
    "за": ["acc", "inst"],
    "под": ["acc", "inst"],
    // Prepositional — в/на map to prep here; acc resolution is handled separately
    "в": ["prep"], "на": ["prep"],
    "о": ["prep"], "об": ["prep"], "обо": ["prep"], "при": ["prep"],
    "во": ["prep"],
]

private let quantityWords: Set<String> = [
    "нет", "много", "мало", "немного", "немало", "несколько",
    "сколько", "столько", "чуть", "чуть-чуть",
]

private let adjectiveSuffixes: [String] = [
    "ого", "его", "ому", "ему", "ыми", "ими",
    "ый", "ий", "ой", "ая", "яя", "ое", "ее", "ые", "ие",
    "ым", "им", "ом", "ей", "ую", "юю",
]

func looksLikeAdjective(_ text: String) -> Bool {
    return adjectiveSuffixes.contains { text.hasSuffix($0) }
}

// Scans backwards from index i-1, skipping tokens that look like adjectives
// (up to maxSkip of them), and returns the first non-adjective token's lowercased
// text -- typically the preposition governing the noun at index i.
private func findPrecedingNonAdjective(_ i: Int, in tokens: [Token], maxSkip: Int = 3) -> String {
    var j = i - 1
    var skipped = 0
    while j >= 0 && skipped < maxSkip && looksLikeAdjective(tokens[j].text.lowercased()) {
        j -= 1
        skipped += 1
    }
    return j >= 0 ? tokens[j].text.lowercased() : ""
}

func calculateNounCaseAnnotations(for text: String, with tokens: [Token]) -> [NounCaseAnnotation] {
    // Pre-compute each token's start position in text.
    var tokenStarts: [Int] = Array(repeating: -1, count: tokens.count)
    var curIndexInText = 0
    for (i, token) in tokens.enumerated() {
        while curIndexInText < text.count &&
              !text.lowercased().substring(from: curIndexInText).starts(with: token.text.lowercased()) {
            curIndexInText += 1
        }
        if curIndexInText < text.count {
            tokenStarts[i] = curIndexInText
        }
        curIndexInText += token.text.count
    }

    var annotations: [NounCaseAnnotation] = []

    for (i, token) in tokens.enumerated() {
        guard tokenStarts[i] >= 0, var nounCase = token.nounCase else { continue }

        let prevText = i > 0 ? tokens[i - 1].text.lowercased() : ""

        if nounCase.hasPrefix("ambiguous_") {
            let ambiguousCases = Set(nounCase.dropFirst("ambiguous_".count).components(separatedBy: "_"))

            // Rule A: try gen via нет/quantity word before, prev token ends with ого/его, or prev token is also a noun.
            let prevEndsWithOgo = prevText.hasSuffix("ого") || prevText.hasSuffix("его")
            let prevIsNoun = i > 0 && tokens[i - 1].nounCase != nil
            let prevIsQuantity = quantityWords.contains(prevText)
            if ambiguousCases.contains("gen") && (prevIsQuantity || prevEndsWithOgo || prevIsNoun) {
                nounCase = "gen"
            } else if let prepCases = prepToCase[findPrecedingNonAdjective(i, in: tokens)] {
                // Rule B: a preposition with several candidate cases (e.g. "с" -> {gen, inst})
                // combined with the noun's own candidate cases may still narrow to one case.
                let resolvedCases = prepCases.intersection(ambiguousCases)
                if resolvedCases.count == 1 {
                    nounCase = resolvedCases.first!
                }
            }
            // else: keep "ambiguous_*" label — rendered as gray in the view
        }

        // в/на + acc (including resolved nom_acc/ambiguous_* -> acc): mark preposition italic as well.
        if (nounCase == "acc" || nounCase == "nom_acc") && (prevText == "в" || prevText == "на") {
            if i > 0 && tokenStarts[i - 1] >= 0 {
                annotations.append(NounCaseAnnotation(
                    position: tokenStarts[i - 1],
                    length: tokens[i - 1].text.count,
                    label: "prep_motion",
                    isItalic: true
                ))
            }
            annotations.append(NounCaseAnnotation(
                position: tokenStarts[i],
                length: token.text.count,
                label: "acc",
                isItalic: true
            ))
            continue
        }

        annotations.append(NounCaseAnnotation(
            position: tokenStarts[i],
            length: token.text.count,
            label: nounCase
        ))
    }

    return annotations.sorted { $0.position < $1.position }
}

func calculateShortAdjectiveAnnotations(for text: String, with tokens: [Token]) -> [ShortAdjectiveAnnotation] {
    var annotations: [ShortAdjectiveAnnotation] = []
    var curIndexInText = 0
    for token in tokens {
        while !text.lowercased().substring(from: curIndexInText).starts(with: token.text.lowercased()) {
            curIndexInText += 1
            if curIndexInText >= text.count { return annotations }
        }
        if token.isShortAdjective == true {
            annotations.append(ShortAdjectiveAnnotation(
                position: curIndexInText,
                length: token.text.count
            ))
        }
        curIndexInText += token.text.count
    }
    return annotations
}
