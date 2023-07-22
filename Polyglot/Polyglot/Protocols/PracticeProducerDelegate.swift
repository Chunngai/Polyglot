//
//  PracticeProducerDelegate.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

protocol PracticeItemDelegate {
    
    associatedtype T: Any
    
    var practice: T { get set }
    
}

protocol PracticeProducerDelegate {
    
    // https://stackoverflow.com/questions/31765806/can-my-class-override-protocol-property-type-in-swift
    
    associatedtype T: Any
    associatedtype U: PracticeItemDelegate
    
    var dataSource: [T] { get set }
    var batchSize: Int { get set }
    
    var practiceList: [U] { get set }
    var currentPracticeIndex: Int { get set }
    var currentPractice: U { get set }
    
    func make() -> [U]
    mutating func next()
    
}

func createWordCardContent(for word: Word, articles: [Article]) -> (word: String, content: String) {  // TODO: - Move elsewhere.
    let wordText: String = {
        if let tokens = word.tokens {
            let textOfTokensLabel = tokens.pronunciationWithAccentList.joined(separator: Strings.wordSeparator)
            if textOfTokensLabel.normalized(
                caseInsensitive: true,
                diacriticInsensitive: true
            ) == word.text.normalized(
                caseInsensitive: true,
                diacriticInsensitive: true
            ) {  // E.g., russian words, japanese words with katakana only.
                return textOfTokensLabel
            } else {
                return "\(word.text) (\(textOfTokensLabel))"
            }
        } else {
            return word.text
        }
    }()
    
    let candidates = articles.paraCandidates(for: word, shouldIgnoreCase: true)
    guard let candidate = candidates.randomElement() else {
        return (word: "", content: wordText)
    }
    
    let sentences = candidate.text.components(from: Variables.tokenizerOfLang(of: .sentence))
    guard let targetSentence = sentences.first(where: { (sentence) -> Bool in
        sentence.contains(word.text)
    }) else {
        return (word: "", content: wordText)
    }
    
    return (
        word: wordText,
        content: targetSentence.replacingOccurrences(
            of: word.text,
            with: "#\(word.text)#"
        )
    )
}
