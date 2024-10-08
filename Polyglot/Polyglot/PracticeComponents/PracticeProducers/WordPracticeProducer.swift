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
        
    // MARK: - Init
    
    override init(words: [Word], articles: [Article]) {
        super.init(words: words, articles: articles)
        
        self.batchSize = self.words.count >= batchSize ?
            batchSize :
            self.words.count
        
        self.practiceList.append(contentsOf: make())
    }
    
    override func make() -> [BasePractice] {
        
//        func calculateProbs() -> [Double] {
//            
//            guard !practices.isEmpty else {
//                return Array<Double>(
//                    repeating: 1.0 / Double(dataSource.count),
//                    count: dataSource.count
//                )
//            }
//            
//            var wordProbMapping: [String: Double] = {
//                var map: [String: Double] = [:]
//                for word in dataSource {
//                    map[word.id] = 0.0
//                }
//                return map
//            }()
//            for practice in practices {
//                guard let word = dataSource.getWord(from: practice.wordId) else {
//                    continue
//                }
//                guard let correctness = practice.correctness else {
//                    continue
//                }
//                
//                print(
//                    practice.practiceType,
//                    {
//                        switch practice.direction {
//                        case .textToMeaning: return dataSource.getWord(from: practice.wordId)!.meaning
//                        case .meaningToText: return dataSource.getWord(from: practice.wordId)!.text
//                        case .text: return dataSource.getWord(from: practice.wordId)!.text
//                        }
//                    }(),
//                    correctness
//                )
//                
//                let val: Double = {
//                    
//                    if practice.practiceType == .accentSelection {
//                        return 0  // TODO: No weights for accent selection.
//                    }
//                    
//                    switch correctness {
//                    case .correct:
//                        return -1  // Decrease the weight.
//                    case .incorrect:
//                        return +1  // Increase the weight.
//                    case .partiallyCorrect:
//                        return 0  // Keep the weight unchanged.
//                    }
//                }()
//                
//                wordProbMapping[word.id]! += val
//            }
//            
//            var probs: [Double] = []
//            for word in dataSource {
//                let prob = wordProbMapping[word.id]!
//                probs.append(prob)
//            }
//            
//            probs = probs.toPositives()!
//            for (word, prob) in zip(dataSource, probs) {
//                print("\(word.text):\(prob)", terminator: " ")
//            }
//            print()
//            
//            return probs
//        }
        
//        let probs = calculateProbs()
        
        // Randomly choose some words.
        var randomWords: [Word] = []
        while true {
            let randomWord = self.words.randomElement()!
            if !randomWords.contains(randomWord) {
                randomWords.append(randomWord)
            }
            if randomWords.count >= batchSize {
                break
            }
        }
        
        var practiceList: [WordPracticeProducer.Item] = []
        for randomWord in randomWords {
                        
            if self.words.count >= WordPracticeProducer.defaultChoiceNumber {
                practiceList.append(makeMeaningSelectionPractice(for: randomWord, in: .textToMeaning))
            }
            practiceList.append(makeMeaningFillingPractice(for: randomWord, in: .meaningToText))

            if self.words.count >= WordPracticeProducer.defaultChoiceNumber,
                let contextSelectionPractice = makeContextSelectionPractice(for: randomWord) {
                practiceList.append(contextSelectionPractice)
            }

            if let reorderingPractice = makeReorderingPractice(for: randomWord) {
                practiceList.append(reorderingPractice)
            }
            
            if let accentSelectionPractice = makeAccentSelectionPractice(for: randomWord) {
                practiceList.append(accentSelectionPractice)
            }
        }
        practiceList.shuffle()
        
        return practiceList
    }
    
    var choiceNumber: Int = WordPracticeProducer.defaultChoiceNumber
}

extension WordPracticeProducer {
    
    func submit(answer: String) {
        guard let currentPractice = currentPractice as? WordPracticeProducer.Item else {
            return
        }
        currentPractice.checkCorrectness(answer: answer)
        
        if currentPractice.practice.correctness != .correct {
            // Re-add the practice for reinforcement.
            DispatchQueue.global(qos: .userInitiated).async {
                
                // Re-create the practice.
                // TODO: - Copy it in a more elegant way.
                let practiceForReinforcement = WordPracticeProducer.Item(
                    practice: WordPractice(
                        practiceType: currentPractice.practice.practiceType,
                        wordId: currentPractice.practice.wordId,
                        selectionWordsIds: currentPractice.practice.selectionWordsIds,
                        selectionAccentsList: currentPractice.practice.selectionAccentsList,
                        articleId: currentPractice.practice.articleId,
                        paragraphId: currentPractice.practice.paragraphId,
                        direction: currentPractice.practice.direction,
                        correctness: nil  // Reset the correctness.
                    ),
                    wordInPrompt: currentPractice.wordInPrompt,
                    prompt: currentPractice.prompt,
                    selectionTexts: currentPractice.selectionTexts,
                    context: currentPractice.context,
                    wordsToReorder: currentPractice.wordsToReorder,
                    key: currentPractice.key,
                    isForReinforcement: true  // Specify that it is for reinforcement.
                )
                
                self.practiceList.append(practiceForReinforcement)
                
            }
        }
    }
    
}

extension WordPracticeProducer {
        
    private func makePromptTemplate(for practiceType: WordPractice.PracticeType) -> String {
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
    
    private func makePrompt(for practiceType: WordPractice.PracticeType, withWord wordInPrompt: String) -> String {
        return makePromptTemplate(for: practiceType).replacingOccurrences(
            of: Strings.maskToken,
            with: wordInPrompt
        )
    }
    
    private func makeSelectionWords(for wordToPractice: Word) -> [Word] {
        var selectionWords: [Word] = [wordToPractice]
        // Randomly choose two words.
        while true {
            let selectionWord = self.words.randomElement()!
            if !selectionWords.contains(selectionWord) {
                selectionWords.append(selectionWord)
            }
            
            if selectionWords.count == choiceNumber {
                break
            }
        }
        selectionWords.shuffle()
        return selectionWords
    }
    
    private func makeMeaningSelectionPractice(for wordToPractice: Word, in randomDirection: PracticeDirection) -> WordPracticeProducer.Item {
        let selectionWords = makeSelectionWords(for: wordToPractice)
        let wordInPrompt: String = randomDirection == .textToMeaning ?
            wordToPractice.text :
            wordToPractice.meaning
        
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .meaningSelection,
                wordId: wordToPractice.id,
                selectionWordsIds: selectionWords.compactMap({ $0.id }),
                direction: randomDirection
            ),
            wordInPrompt: wordInPrompt,
            prompt: makePrompt(for: .meaningSelection, withWord: wordInPrompt),
            selectionTexts: selectionWords.compactMap({ (word) -> String in
                randomDirection == .textToMeaning ?
                    word.meaning :
                    word.text
            }),
            key: randomDirection == .textToMeaning ?
                wordToPractice.meaning :
                wordToPractice.text
        )
    }
    
    private func makeMeaningFillingPractice(for wordToPractice: Word, in randomDirection: PracticeDirection) -> WordPracticeProducer.Item {
        let wordInPrompt = randomDirection == .textToMeaning ?
            wordToPractice.text :
            wordToPractice.meaning
        
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .meaningFilling,
                wordId: wordToPractice.id,
                direction: randomDirection
            ),
            wordInPrompt: wordInPrompt,
            prompt: makePrompt(for: .meaningFilling, withWord: wordInPrompt),
            key: randomDirection == .textToMeaning ?
                wordToPractice.meaning :
                wordToPractice.text
        )
    }
    
    private func makeContextSelectionPractice(for wordToPractice: Word) -> WordPracticeProducer.Item? {
        
        let candidates = articles.paraCandidates(for: wordToPractice.text)
        guard candidates.count != 0,
              let candidate = candidates.randomElement() else {
            return nil
        }
        
        let selectionWords = makeSelectionWords(for: wordToPractice)
        
//         Take care of the normalization.
//        let rangeOfWordToPractice = candidate.text.normalized(caseInsensitive: true, diacriticInsensitive: true).range(of: wordToPractice.text.normalized(caseInsensitive: true, diacriticInsensitive: true))
        let context = candidate.text.replacingOccurrences(
            of: wordToPractice.text,
            with: Strings.underscoreToken,
            options: [.caseInsensitive, .diacriticInsensitive]
//            range: rangeOfWordToPractice
        )
        
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .contextSelection,
                wordId: wordToPractice.id,
                selectionWordsIds: selectionWords.compactMap( {$0.id} ),
                articleId: candidate.articleId,
                paragraphId: candidate.paraId,
                direction: .text
            ),
            wordInPrompt: wordToPractice.text,
            prompt: makePrompt(for: .contextSelection, withWord: wordToPractice.text),
            selectionTexts: selectionWords.compactMap( {$0.text} ),
            context: context,
            key: wordToPractice.text
        )
    }
    
    private func makeAccentSelectionPractice(for wordToPractice: Word) -> WordPracticeProducer.Item? {
        
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
        
        guard let tokens = wordToPractice.tokens,
            // Not needed for one-syllable words.
            tokens.pronunciations.joined(separator: "").count >= 2 else {
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
            
            if selectionAccentsList.count == choiceNumber {
                break
            }
        }
                
        // Shuffle the two lists in the same order.
        // https://stackoverflow.com/questions/32726962/randomize-two-arrays-the-same-way-swift
        let shuffledIndices = selectionAccentsList.indices.shuffled()
        selectionAccentsList = shuffledIndices.map { selectionAccentsList[$0] }
        selectionTexts = shuffledIndices.map { selectionTexts[$0] }
                
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .accentSelection,
                wordId: wordToPractice.id,
                selectionAccentsList: selectionAccentsList,
                direction: .text
            ),
            wordInPrompt: wordToPractice.text,
            prompt: makePrompt(for: .accentSelection, withWord: wordToPractice.text),
            selectionTexts: selectionTexts,
            key: tokens.accentedPronunciations.joined(separator: Strings.wordSeparator)
        )
        
    }
    
    private func makeReorderingPractice(for wordToPractice: Word) -> WordPracticeProducer.Item? {
        
        let candidates = articles.paraCandidates(for: wordToPractice.text)
        guard candidates.count != 0,
              let candidate = candidates.randomElement() else {
            return nil
        }
        
        let sentences = candidate.text.tokenized(with: LangCode.currentLanguage.sentenceTokenizer)
        guard let targetSentence = sentences.first(where: { (sentence) -> Bool in
            sentence.contains(wordToPractice.text)
        }) else {
            return nil
        }
        
        // Using the whole target sentence will
        // result in too many words,
        // so use the target subsentence instead.
        let subSentences = targetSentence.split(with: Strings.subsentenceSeparator)
        guard let targetSubSentence = subSentences.first(where: { (subSentence) -> Bool in
            subSentence.contains(wordToPractice.text)
        }) else {
            return nil
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
            return nil
        }
        
        // Check line number.
        // TODO: - Update here. It's not proper to call calculateRowNumber() here.
        if ReorderingPracticeView.calculateRowNumber(words: words) > 3 {
            print("The subsentence is too long. Skipping.")
            return nil
        }
        
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .reordering,
                wordId: wordToPractice.id,
                articleId: candidate.articleId,
                paragraphId: candidate.paraId,
                direction: .text
            ),
            wordInPrompt: wordToPractice.text,  // TODO: - Remove this line.
            prompt: makePrompt(for: .reordering, withWord: wordToPractice.text),
            wordsToReorder: words,
            key: words.joined(separator: Strings.wordSeparator)
        )
    }
}

extension WordPracticeProducer {
    
    class Item: BasePractice {
        
        var practice: WordPractice
        
        var wordInPrompt: String
        var prompt: String
        
        var selectionTexts: [String]?
        var context: String?
        var wordsToReorder: [String]?
        
        var key: String
        
        var isForReinforcement: Bool = false  // True for re-added practices (with wrong answers).
        
        var tokenizer: NLTokenizer {
            let lang: LangCode = {
                switch practice.direction {
                case .textToMeaning: return LangCode.currentLanguage.configs.languageForTranslation
                case .meaningToText: return LangCode.currentLanguage
                case .text: return LangCode.currentLanguage
                }
            }()
//            print(lang)
            
            if lang == LangCode.currentLanguage {
                return LangCode.currentLanguage.wordTokenizer
            } else {
                return LangCode.currentLanguage.configs.languageForTranslation.wordTokenizer
            }
        }
        
        init(
            practice: WordPractice,
            wordInPrompt: String,
            prompt: String,
            selectionTexts: [String]? = nil,
            context: String? = nil,
            wordsToReorder: [String]? = nil,
            key: String,
            isForReinforcement: Bool = false
        ) {
            self.practice = practice
            self.wordInPrompt = wordInPrompt
            self.prompt = prompt
            self.selectionTexts = selectionTexts
            self.context = context
            self.wordsToReorder = wordsToReorder
            self.key = key
            self.isForReinforcement = isForReinforcement
        }
                
        func checkCorrectness(answer: String) {
            
            // Do not normalize for accent practices,
            // or the accent mark will be removed.
            let shouldIgnoreCaseAndAccent = practice.practiceType == .meaningFilling
            
            let key = self.key.normalized(caseInsensitive: shouldIgnoreCaseAndAccent, diacriticInsensitive: shouldIgnoreCaseAndAccent)
            let answer = answer.normalized(caseInsensitive: shouldIgnoreCaseAndAccent, diacriticInsensitive: shouldIgnoreCaseAndAccent)
            
            let keyComponents = key.tokenized(with: tokenizer)
            let answerComponents = answer.tokenized(with: tokenizer)
            
            if keyComponents == answerComponents {
                // Totally correct, including word order.
                practice.correctness = .correct
            } else {
                if !Set(keyComponents).intersection(Set(answerComponents)).isEmpty {
                    practice.correctness = .partiallyCorrect
                } else {
                    practice.correctness = .incorrect
                }
            }
        }
    }
}

extension WordPracticeProducer {
    
    // MARK: - Constants
    
    private static let defaultChoiceNumber: Int = 3
    
}
