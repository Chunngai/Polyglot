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

func makeParaCandidates(for word: Word, shouldIgnoreCaseAndAccent: Bool) -> [(articleId: String, paraId: String, text: String)] {  // TODO: - Move elsewhere.
    
    let wordText: String = word.text.normalized(caseInsensitive: shouldIgnoreCaseAndAccent, diacriticInsensitive: shouldIgnoreCaseAndAccent)
    
    var candidates: [(articleId: String, paraId: String, text: String)] = []
    for article in Article.load() {  // TODO: - Is it proper to load articles here?
        for para in article.paras {
            
            let paraText: String = para.text.normalized(caseInsensitive: shouldIgnoreCaseAndAccent, diacriticInsensitive: shouldIgnoreCaseAndAccent)
            
            if paraText.contains(wordText) {
                candidates.append((articleId: article.id, paraId: para.id, text: para.text))
            }
        }
    }
    return candidates
}

func createWordCardContent(words: [Word], articles: [Article]) -> (word: String, content: String) {  // TODO: - Move elsewhere.
    let randomWord = words.randomElement()!
    
    let candidates = makeParaCandidates(for: randomWord, shouldIgnoreCaseAndAccent: true)
    guard let candidate = candidates.randomElement() else {
        return (word: "", content: randomWord.text)
    }
    
    let sentences = candidate.text.components(from: Variables.tokenizerOfLang(of: .sentence))
    guard let targetSentence = sentences.first(where: { (sentence) -> Bool in
        sentence.contains(randomWord.text)
    }) else {
        return (word: "", content: randomWord.text)
    }
    
    return (
        word: randomWord.text,
        content: targetSentence.replacingOccurrences(
            of: randomWord.text,
            with: "#\(randomWord.text)#"
        )
    )
}
