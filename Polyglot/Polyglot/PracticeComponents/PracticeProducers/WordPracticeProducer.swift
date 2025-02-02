//
//  WordPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import UIKit
import NaturalLanguage

class WordPracticeProducer: BasePracticeProducer {
    
    var variantNumber: Int = 5  // TODO: -
    
    static func getWord2Count(from practiceList: [BasePractice]) -> [String: Int] {
        
        var word2count: [String: Int] = [:]
        for wordPractice in practiceList {
            guard let wordPractice = wordPractice as? WordPractice else {
                continue
            }
            let word = wordPractice.word
            if word2count.keys.contains(word) {
                word2count[word]! += 1
            } else {
                word2count[word] = 1
            }
        }
        return word2count
        
    }
    static var word2count: [String: Int] = WordPracticeProducer.getWord2Count(from: WordPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage))
    
    override var practiceList: [BasePractice] {
        didSet {
            Self.word2count = Self.getWord2Count(from: self.practiceList)
        }
    }
    
    // MARK: - Init
    
    override init(words: [Word], articles: [Article]) {
        super.init(words: words, articles: articles)
        
        let cachedWordPractices = WordPracticeProducer.loadCachedPractices(for: LangCode.currentLanguage)
        if !cachedWordPractices.isEmpty {
            self.practiceList.append(contentsOf: cachedWordPractices)
            self.practiceList.shuffle()
        }
        
    }
    
    override func next() {
        
        let wordPractice = self.practiceList.remove(at: 0)
        if let wordPractice = wordPractice as? WordPractice,
           Self.word2count.keys.contains(wordPractice.word) {
            
            Self.word2count[wordPractice.word]! -= 1
            if Self.word2count[wordPractice.word]! <= 0 {
                Self.word2count.removeValue(forKey: wordPractice.word)
            }
            
        }
        
    }
    
    override func cache() {
        guard var practicesToCache = self.practiceList as? [WordPractice] else {
            return
        }
        WordPracticeProducer.save(
            &practicesToCache,
            for: LangCode.currentLanguage
        )
    }
}

extension WordPracticeProducer {
    
    func makeAndCachePractices(for words: [String]) {
        
        for word in words {
            
            machineTranslator.translate(query: word) { translations, _ in
                
                guard !translations.isEmpty else {
                    return
                }
                let meaning = translations.joined(separator: "; ")
                
                if let practice = self.makeMeaningSelectionPractice(
                    word: word,
                    query: word,
                    key: meaning,
                    direction: .textToMeaning
                ) {
                    self.practiceList.append(practice)
                }
                if let practice = self.makeMeaningSelectionPractice(
                    word: word,
                    query: meaning,
                    key: word,
                    direction: .meaningToText
                ) {
                    self.practiceList.append(practice)
                }
                
                let practice = self.makeMeaningFillingPractice(
                    word: word,
                    query: meaning,
                    key: word,
                    direction: .meaningToText
                )
                self.practiceList.append(practice)
               
                self.cache()
                
            }
            
            analyzeAccents(for: word) { tokens, fixedText, text in
                
                if let practice = self.makeAccentSelectionPractice(
                    word: fixedText ?? text,
                    query: fixedText ?? text,
                    tokens: tokens
                ) {
                    self.practiceList.append(practice)
                    self.cache()
                }
                
            }

            if let practice = makeContextSelectionPractice(
                word: word,
                query: word
               ) {
                practiceList.append(practice)
            }

            makeReorderingPractice(
                word: word,
                query: word,
                completion: { practice in
                
                    if let practice = practice {
                        self.practiceList.append(practice)
                        self.cache()
                    }
                    
            })
            
            cache()
            
        }

    }
    
}

extension WordPracticeProducer {
    
    func submit(answer: String) {
        
        guard let currentPractice = currentPractice as? WordPractice else {
            return
        }
        currentPractice.checkCorrectness(answer: answer)
        
        if currentPractice.correctness != .correct {
            // Re-add the practice for reinforcement.
            DispatchQueue.global(qos: .userInitiated).async {
                // Re-create the practice.
                let practiceForReinforcement = WordPractice(from: currentPractice)
                practiceForReinforcement.correctness = nil
                
                self.practiceList.append(practiceForReinforcement)
            }
        }
    }
    
}

extension WordPracticeProducer {
        
    private func promptTemplate(for practiceType: WordPractice.PracticeType) -> String {
        
        switch practiceType {
        case .meaningSelection, .meaningFilling:
            return Strings.meaningSelectionAndFillingPracticePrompt
        case .contextSelection:
            return Strings.contextSelectionPracticePrompt
        case .accentSelection:
            return Strings.accentSelectionPracticePrompt
        case .reordering:
            return Strings.reorderingPracticePrompt
        }
        
    }
    
    private func prompt(for practiceType: WordPractice.PracticeType, withWord wordInPrompt: String) -> String {
        return promptTemplate(for: practiceType).replacingOccurrences(
            of: Strings.maskToken,
            with: wordInPrompt
        )
    }
    
    private func choices(for wordToPractice: String) -> [String]? {
        
        guard self.words.count >= Self.defaultChoiceNumber else {
            return nil
        }
        
        var choices: [String] = [wordToPractice]
        // Randomly choose words.
        while true {
            let choice = self.words.randomElement()!
            if !choices.contains(choice.text) {
                choices.append(choice.text)
            }
            
            if choices.count == Self.defaultChoiceNumber {
                break
            }
        }
        choices.shuffle()
        return choices
        
    }
    
    private func makeMeaningSelectionPractice(
        word: String,
        query: String,
        key: String,
        direction: WordPractice.PracticeDirection
    ) -> WordPractice? {
        
        guard let choices = choices(for: key) else {
            return nil
        }
        
        return WordPractice(
            practiceType: .meaningSelection,
            word: word,
            query: query,
            key: key,
            prompt: prompt(for: .meaningSelection, withWord: query),
            choices: choices,
            direction: direction
        )
        
    }
    
    private func makeMeaningFillingPractice(
        word: String,
        query: String,
        key: String,
        direction: WordPractice.PracticeDirection
    ) -> WordPractice {
        
        return WordPractice(
            practiceType: .meaningFilling,
            word: word,
            query: query,
            key: key,
            prompt: prompt(for: .meaningFilling, withWord: query),
            direction: direction
        )
        
    }
    
    private func makeContextSelectionPractice(
        word: String,
        query: String
    ) -> WordPractice? {
        
        let candidates = articles.paraCandidates(for: query)
        guard candidates.count != 0,
              let candidate = candidates.randomElement() 
        else {
            return nil
        }
        
        guard let choices = choices(for: query) else {
            return nil
        }
        
        return WordPractice(
            practiceType: .contextSelection,
            word: word,
            query: query,
            key: query,
            prompt: prompt(for: .contextSelection, withWord: query),
            choices: choices,
            context: candidate.text.replacingOccurrences(
                of: query,
                with: Strings.underscoreToken,
                options: [.caseInsensitive, .diacriticInsensitive]
            ),
            articleId: candidate.articleId,
            paragraphId: candidate.paraId,
            direction: .text
        )
        
    }
    
    private func makeAccentSelectionPractice(
        word: String,
        query: String,
        tokens: [Token]
    ) -> WordPractice? {
        
        // TODO: - nil and -1 produces the same accented pronunciation.
        
        func makePronunciationsWith(accents: [Int?], and tokens: [Token]) -> String {
            guard accents.count == tokens.count else {
                return "-"
            }
            
            var tokens = tokens
            for (i, accent) in accents.enumerated() {
                tokens[i].accentLoc = accent
            }
            return tokens.accentedPronunciations.joined(separator: Strings.wordSeparator)
        }
        
        func generateRandomAccentLocs(for tokens: [Token]) -> [Int?] {
            return tokens.pronunciations.map({ (pronunciation) -> Int? in
                if pronunciation.count > 1 {  // Old jp accent interface.
                    // E.g., if the pronunciation has two chars,
                    // vals will be [0, 1].
                    var vals: [Int?] = Array<Int>(0..<pronunciation.count)
                    // Add a nil for other situations, e.g., no accent.
                    vals += [nil]
                    
                    return vals.randomElement()!
                } else {  // New jp accent interface.
                    let rand: Float = Float.random(in: 0...1)
                    if rand < 0.8 {  // No accent in most cases.
                        return nil
                    } else {
                        return 0
                    }
                }
            })
        }
        
        // Not needed for one-syllable words.
        guard tokens.pronunciations.joined(separator: "").count >= 2 else {
            return nil
        }
        
        var selectionAccentsList = [tokens.accentLocs]
        var selectionTexts = [tokens.accentedPronunciations.joined(separator: Strings.wordSeparator)]
        // Randomly generate two accent sequences.
        while true {
            // Generate a random accent sequence.
            let selectionAccents = generateRandomAccentLocs(for: tokens)
            let selectionText = makePronunciationsWith(accents: selectionAccents, and: tokens)
            if !selectionTexts.contains(selectionText) {
                selectionAccentsList.append(selectionAccents)
                selectionTexts.append(selectionText)
            }
            
            if selectionAccentsList.count == Self.defaultChoiceNumber {
                break
            }
        }
                
        // Shuffle the two lists in the same order.
        // https://stackoverflow.com/questions/32726962/randomize-two-arrays-the-same-way-swift
        let shuffledIndices = selectionAccentsList.indices.shuffled()
        selectionTexts = shuffledIndices.map { selectionTexts[$0] }
                
        return WordPractice(
            practiceType: .accentSelection,
            word: word,
            query: query,
            key: tokens.accentedPronunciations.joined(separator: Strings.wordSeparator),
            prompt: prompt(for: .accentSelection, withWord: query),
            choices: selectionTexts,
            direction: .text
        )
        
    }
    
    private func makeReorderingPractice(
        word: String,
        query: String,
        completion: @escaping (WordPractice?) -> Void
    ) {
        
        let candidates = articles.paraCandidates(for: query)
        guard candidates.count != 0,
              let candidate = candidates.randomElement() 
        else {
            completion(nil)
            return
        }
        
        let sentences = candidate.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
        guard let targetSentence = sentences.first(where: { (sentence) -> Bool in
            sentence.contains(query)
        }) else {
            completion(nil)
            return
        }
        
        // Using the whole target sentence will
        // result in too many words,
        // so use the target subsentence instead.
        let subSentences = targetSentence.split(with: Strings.subsentenceSeparator)
        guard let targetSubSentence = subSentences.first(where: { (subSentence) -> Bool in
            subSentence.contains(query)
        }) else {
            completion(nil)
            return
        }
        
        // Reduce the number of tokens.
        // TODO: - Improvement.
        let rawWords = targetSubSentence.tokenized(with: LangCode.currentLanguage.wordTokenizer)
        var words: [String] = []
        if LangCode.currentLanguage == LangCode.ja {
            var indexOfLastWord: Int = -1
            for i in 0..<rawWords.count {
                let rawWord = rawWords[i]
                if i > 0 && Tokens.japaneseParticles.contains(rawWord) {
                    words[indexOfLastWord] = words[indexOfLastWord] + rawWord
                } else {
                    words.append(rawWord)
                    indexOfLastWord += 1
                }
            }
        } else {
            words = rawWords
        }
        
        if words.isEmpty {
            print("Empty words. Target subsentence: \(targetSubSentence). Skipping.")
            completion(nil)
        }
        
        // Check line number.
        // TODO: - Update here. It's not proper to call calculateRowNumber() here.
//        if ReorderingPracticeView.calculateRowNumber(words: words) > 3 {
//            print("The subsentence is too long. Skipping. Subsentence: \(targetSentence)")
//            completion(nil)
//        }
        
        machineTranslator.translate(query: targetSubSentence) { translations, _ in
            guard let translation = translations.first else {
                completion(nil)
                return
            }
            completion(WordPractice(
                practiceType: .reordering,
                word: word,
                query: query,
                key: words.joined(separator: Strings.wordSeparator),
                prompt: self.prompt(for: .reordering, withWord: query),
                reorderingWordList: words,
                reorderingTextTranslation: translation,
                articleId: candidate.articleId,
                paragraphId: candidate.paraId,
                direction: .text
            ))
        }
                
    }
}

extension WordPracticeProducer {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "cachedWordPractices.\(lang).json"
    }
    
    static func loadCachedPractices(for lang: LangCode) -> [WordPractice] {
        do {
            let practices = try readDataFromJson(
                fileName: WordPracticeProducer.fileName(for: lang.rawValue),
                type: [WordPractice].self
            ) as? [WordPractice] ?? []

            return practices
        } catch {
            print(error)
            return []
        }
    }
    
    static func save(_ practicesToCache: inout [WordPractice], for lang: LangCode) {
        for practice in practicesToCache {
            print(practice.query, practice.practiceType)
        }
        do {
            try writeDataToJson(
                fileName: WordPracticeProducer.fileName(for: lang.rawValue),
                data: practicesToCache
            )
        } catch {
            print(error)
        }
    }
    
}


extension WordPracticeProducer {
    
    // MARK: - Constants
    
    private static let defaultChoiceNumber: Int = 3
    
}
