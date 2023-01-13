//
//  WordPracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2023/1/8.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

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
        // Randomly choose 10 words.
        var randomWords: [Word] = []
        for _ in 0..<10 {
            let randomWord = dataSource.randomElement()!
            if !randomWords.contains(randomWord) {
                randomWords.append(randomWord)
            }
        }
        
        var practiceList: [WordPracticeProducer.Item] = []
        for randomWord in randomWords {
            for direction in Array<UInt>(arrayLiteral: 0, 1) {
                practiceList.append(makeMeaningSelectionPractice(for: randomWord, in: direction))
                practiceList.append(makeMeaningFillingPractice(for: randomWord, in: direction))
            }
        }
        practiceList.shuffle()
        
        return practiceList
    }
    
    mutating func next() {
        currentPracticeIndex += 1
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
    
    private func makeMeaningSelectionPractice(for wordToPractice: Word, in randomDirection: UInt) -> WordPracticeProducer.Item {
        var selectionWords: [Word] = [wordToPractice]
        // Randomly choose two words.
        while true {
            let selectionWord = dataSource.randomElement()!
            if !selectionWords.contains(selectionWord) {
                selectionWords.append(selectionWord)
            }
            
            if selectionWords.count == 3 {
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
                with: randomDirection == 0 ?
                    wordToPractice.text :
                    wordToPractice.meaning
            ),
            selectionTexts: selectionWords.compactMap({ (word) -> String in
                randomDirection == 0 ?
                    word.meaning :
                    word.text
            }),
            key: randomDirection == 0 ?
                wordToPractice.meaning :
                wordToPractice.text
        )
    }
    
    private func makeMeaningFillingPractice(for wordToPractice: Word, in randomDirection: UInt) -> WordPracticeProducer.Item {
        return WordPracticeProducer.Item(
            practice: WordPractice(
                practiceType: .meaningFilling,
                wordId: wordToPractice.id,
                direction: randomDirection
            ),
            prompt: makePromptTemplate(for: .meaningFilling).replacingOccurrences(
                of: Strings.maskToken,
                with: randomDirection == 0 ?
                    wordToPractice.text :
                    wordToPractice.meaning
            ),
            key: randomDirection == 0 ?
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
    }
    
}

extension WordPractice {
    
    enum Correctness: UInt, Codable {
        
        case incorrect
        case correct
        case partiallyCorrect  // E.g., for meaning filling.
    }
    
    var correctness: Correctness {
        switch self.practiceType {
        case .meaningSelection, .contextSelection:
            if self.wordId == self.answer {
                return .correct
            } else {
                return .incorrect
            }
        case .meaningFilling:  // TODO: - Consider partial correctness.
            let key: String!
            if direction == 0 {
                key = Word.load().getWord(from: wordId)?.meaning  // TODO: load()
            } else {
                key = Word.load().getWord(from: wordId)?.text  // TODO: load()
            }
            
            if key == answer {
                return .correct
            } else {
                return .incorrect
            }
        }
    }
}
