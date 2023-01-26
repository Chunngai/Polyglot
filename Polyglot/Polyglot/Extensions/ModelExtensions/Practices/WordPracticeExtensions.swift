//
//  WordPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

struct WordPracticeProducer: PracticeProducerDelegate {
    
    typealias T = Word
    typealias U = WordPracticeProducer.Item
    
    var dataSource: [Word] {
        didSet {
            
            if dataSource.isEmpty {
                dataSource.append(Word.dummyWord)
            }
        }
    }
    
    var practiceList: [WordPracticeProducer.Item]
    var currentPracticeIndex: Int {
        didSet {
            if currentPracticeIndex >= practiceList.count {
                practiceList.append(contentsOf: make())
            }
        }
    }
    var currentPractice: WordPracticeProducer.Item {
        get {
            return practiceList[currentPracticeIndex]
        }
        set {
            practiceList[currentPracticeIndex] = newValue
        }
    }
    
    init(words: [Word]) {
        self.dataSource = words
        
        self.practiceList = []
        self.currentPracticeIndex = 0
        
        self.practiceList.append(contentsOf: make())
    }
    
    func make() -> [WordPracticeProducer.Item] {
        
        func calculateProbs() -> [Double] {
            
            guard !practices.isEmpty else {
                return Array<Double>(
                    repeating: 1.0 / Double(dataSource.count),
                    count: dataSource.count
                )
            }
            
            var wordProbMapping: [String: Double] = {
                var map: [String: Double] = [:]
                for word in dataSource {
                    map[word.id] = 0.0
                }
                return map
            }()
            for practice in practices {
                guard let word = dataSource.getWord(from: practice.wordId) else {
                    continue
                }
                guard let correctness = practice.correctness else {
                    continue
                }
                
                print(
                    practice.practiceType,
                    practice.direction == .textToMeaning ?
                        dataSource.getWord(from: practice.wordId)!.meaning :
                        dataSource.getWord(from: practice.wordId)!.text,
                    correctness
                )
                
                let val: Double = {
                    switch correctness {
                    case .correct:
                        return -1  // Decrease the weight.
                    case .incorrect:
                        return +1  // Increase the weight.
                    case .partiallyCorrect:
                        return 0  // Keep the weight unchanged.
                    }
                }()
                
                wordProbMapping[word.id]! += val
            }
            
            var probs: [Double] = []
            for word in dataSource {
                let prob = wordProbMapping[word.id]!
                probs.append(prob)
            }
            
            probs = probs.toNonNegatives()!
            print(probs)
            
            return probs
        }
        
        let probs = calculateProbs()
        
        // Randomly choose some words.
        var randomWords: [Word] = []
        while true {
            let randomWord = dataSource.randomElement(from: probs)!
            if !randomWords.contains(randomWord) {
                randomWords.append(randomWord)
            }
            if randomWords.count == WordPracticeProducer.batchSize {
                break
            }
        }
        
        var practiceList: [WordPracticeProducer.Item] = []
        for randomWord in randomWords {
            
            practiceList.append(makeMeaningSelectionPractice(for: randomWord, in: .textToMeaning))
            practiceList.append(makeMeaningSelectionPractice(for: randomWord, in: .meaningToText))
            
            practiceList.append(makeMeaningFillingPractice(for: randomWord, in: .meaningToText))
            
        }
        practiceList.shuffle()
        
        return practiceList
    }
    
    mutating func next() {
        currentPracticeIndex += 1
    }
    
    private static let batchSize: Int = 6
    private static let choiceNumber: Int = 3
    
    private var practices: [WordPractice] = WordPractice.load()
}

extension WordPracticeProducer {
    
    mutating func submit(answer: String) {
        currentPractice.checkCorrectness(answer: answer)
    }
    
}

extension WordPracticeProducer {
        
    private func makePromptTemplate(for practiceType: WordPractice.PracticeType) -> String {
        switch practiceType {
        case .meaningSelection, .meaningFilling:
            return Strings.meaningSelectionAndFillingPracticePrompt
        case .contextSelection:
            return Strings.contextSelectionPracticePrompt
        }
        
    }
    
    private func makeMeaningSelectionPractice(for wordToPractice: Word, in randomDirection: PracticeDirection) -> WordPracticeProducer.Item {
        var selectionWords: [Word] = [wordToPractice]
        // Randomly choose two words.
        while true {
            let selectionWord = dataSource.randomElement()!
            if !selectionWords.contains(selectionWord) {
                selectionWords.append(selectionWord)
            }
            
            if selectionWords.count == WordPracticeProducer.choiceNumber {
                break
            }
        }
        selectionWords.shuffle()
        
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .meaningSelection,
                wordId: wordToPractice.id,
                selectionWordsIds: selectionWords.compactMap({ (word) -> String in
                    word.id
                }),
                direction: randomDirection
            ),
            prompt: makePromptTemplate(for: .meaningSelection).replacingOccurrences(
                of: Strings.maskToken,
                with: randomDirection == .textToMeaning ?
                    wordToPractice.text :
                    wordToPractice.meaning
            ),
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
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .meaningFilling,
                wordId: wordToPractice.id,
                direction: randomDirection
            ),
            prompt: makePromptTemplate(for: .meaningFilling).replacingOccurrences(
                of: Strings.maskToken,
                with: randomDirection == .textToMeaning ?
                    wordToPractice.text :
                    wordToPractice.meaning
            ),
            key: randomDirection == .textToMeaning ?
                wordToPractice.meaning :
                wordToPractice.text
        )
    }
}

extension WordPracticeProducer {
    
    struct Item: PracticeItemDelegate {
        
        typealias T = WordPractice
        
        var practice: WordPractice
        
        var prompt: String
        
        var selectionTexts: [String]?
        var context: String?
        
        var key: String
        
        var tokenizer: NLTokenizer {
            let lang = practice.direction == .textToMeaning ?
                Variables.pairedLang :
                Variables.lang
            print(lang)
            
            let tokenizer = NLTokenizer(unit: .word)
            tokenizer.setLanguage(LangCode.toNLLanguage(langCode: lang))
            
            return tokenizer
        }
        
        mutating func checkCorrectness(answer: String) {
            let keyComponents = key.normalized.components(from: tokenizer)
            let answerComponents = answer.normalized.components(from: tokenizer)
            
            let correctness: WordPractice.Correctness!
            if keyComponents == answerComponents {
                correctness = .correct
            } else {
                if !Set(keyComponents).intersection(Set(answerComponents)).isEmpty {
                    correctness = .partiallyCorrect
                } else {
                    correctness = .incorrect
                }
            }
            
            practice.correctness = correctness
        }
    }
}

extension WordPracticeProducer {
    
    // MARK: - IO
    
    mutating func save() {
        var practicesToSave: [WordPractice] = []
        for practiceIndex in 0..<currentPracticeIndex {
            practicesToSave.append(practiceList[practiceIndex].practice)
        }
        if currentPractice.practice.correctness != nil {
            practicesToSave.append(currentPractice.practice)
        }
        
        practices.append(contentsOf: practicesToSave)
        WordPractice.save(&practices)
    }
}
