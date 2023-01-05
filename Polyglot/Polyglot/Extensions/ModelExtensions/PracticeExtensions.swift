//
//  PracticeExtensions.swift
//  Polyglot
//
//  Created by Sola on 2022/12/27.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

extension WordPractice {
    enum Correctness: UInt, Codable {
        
        case incorrect = 0
        case correct = 1
        case partiallyCorrect = 2  // E.g., for meaning filling.
    }
    
    // TODO: - Simplify here.
    var correctness: Correctness {
        switch self.type {
        case .meaningSelection, .contextSelection:
            if self.wordId == self.selectedWordId {
                return .correct
            } else {
                return .incorrect
            }
        case .meaningFilling:  // TODO: - Consider partial correctness.
            let key: String!
            if direction == 0 {
                key = Word.getWord(from: wordId)?.meaning
            } else {
                key = Word.getWord(from: wordId)?.word
            }
            
            if key == typedAnswer {
                return .correct
            } else {
                return .incorrect
            }
        }
    }
}

struct WordPracticeProducer {
    
    var words: [Word]
    
    struct WordPracticeItem {
        
        var practice: WordPractice
        var prompt: String
        var selectionTexts: [String]?
        var context: String?
        var key: String
        
    }
    
    static let maskToken: String = Strings.maskToken
    func makePromptTemplate(for wordPracticeType: WordPractice.WordPracticeType) -> String {
        switch wordPracticeType {
        case .meaningSelection, .meaningFilling:
            return "\(WordPracticeProducer.maskToken)\n\(Strings.meaningSelectionAndFillingPracticePromptSuffix)"
        case .contextSelection:
            return Strings.contextSelectionPracticePrompt
        }
        
    }
    
    private func makeMeaningSelectionPractice(for wordToPractice: Word) -> WordPracticeItem {
        // Randomly choose two words.
        var selectionWordsMapping: [Int: Word] = [wordToPractice.id : wordToPractice]  // The dict can guarantee a random order.
        while true {
            if let selectionWord = words.randomElement(),
                selectionWord.id != wordToPractice.id,
                !selectionWordsMapping.keys.contains(selectionWord.id) {
                
                // Cannot be the word to practice.
                // And cannot be one of the selection words.
                
                selectionWordsMapping[selectionWord.id] = selectionWord
            }
            
            if selectionWordsMapping.count == 3 {
                break
            }
        }
        let selectionWordsIds = Array<Int>(selectionWordsMapping.keys)
        let selectionWords = Array<Word>(selectionWordsMapping.values)
        
        // Randomly choose a direction.
        let randomDirection: UInt = UInt.random(in: 0...1)  // 0-1.
        
        let wordPractice = WordPractice(
            wordId: wordToPractice.id,
            type: .meaningSelection,
            selectionWordsIds: selectionWordsIds,
            direction: randomDirection
        )
        
        let prompt: String!
        let selectionTexts: [String]!
        let key: String!
        let promptTemplate: String = makePromptTemplate(for: .meaningSelection)
        if randomDirection == 0 {  // word -> meaning.
            prompt = promptTemplate.replacingOccurrences(of: WordPracticeProducer.maskToken, with: wordToPractice.word)
            selectionTexts = [selectionWords[0].meaning, selectionWords[1].meaning, selectionWords[2].meaning]
            key = wordToPractice.meaning
        } else {
            prompt = promptTemplate.replacingOccurrences(of: WordPracticeProducer.maskToken, with: wordToPractice.meaning)
            selectionTexts = [selectionWords[0].word, selectionWords[1].word, selectionWords[2].word]
            key = wordToPractice.word
        }
        
        return WordPracticeItem(practice: wordPractice, prompt: prompt, selectionTexts: selectionTexts, key: key)
    }
    
    private func makeMeaningFillingPractice(for wordToPractice: Word) -> WordPracticeItem {
        // Randomly choose a direction.
        let randomDirection: UInt = UInt.random(in: 0...1)  // 0-1.
        
        let wordPractice = WordPractice(
            wordId: wordToPractice.id,
            type: .meaningFilling,
            direction: randomDirection
        )
        
        let prompt: String!
        let key: String!
        let promptTemplate: String = makePromptTemplate(for: .meaningFilling)
        if randomDirection == 0 {  // word -> meaning.
            prompt = promptTemplate.replacingOccurrences(of: WordPracticeProducer.maskToken, with: wordToPractice.word)
            key = wordToPractice.meaning
        } else {
            prompt = promptTemplate.replacingOccurrences(of: WordPracticeProducer.maskToken, with: wordToPractice.meaning)
            key = wordToPractice.word
        }
        
        return WordPracticeItem(practice: wordPractice, prompt: prompt, key: key)
    }
    
    func make() -> [WordPracticeItem] {
        // Randomly choose a word.
        guard let randomWord = words.randomElement() else {
            return []
        }
        
        let wordPracticeType = Int.random(in: 0...1)  // TODO: - Udate here after the context practice is done.
        switch wordPracticeType {
        case WordPractice.WordPracticeType.meaningSelection.rawValue:
            return [makeMeaningSelectionPractice(for: randomWord)]
        case WordPractice.WordPracticeType.meaningFilling.rawValue:
            return [makeMeaningFillingPractice(for: randomWord)]
        case WordPractice.WordPracticeType.contextSelection.rawValue:
            return []
        default:
            return []
        }
    }
}

struct ReadingPracticeProducer {
    
    var articles: [Article]
    
    struct ReadingPracticeItem {
        
        var practice: ReadingPractice
        var text: String
        var meaning: String?
    }
    
    // TODO: - Update
    func make() -> [ReadingPracticeItem] {
        // Randomly choose an article.
        guard let randomArticle = articles.randomElement() else {
            return []
        }
        
        var readingPracticeList: [ReadingPracticeItem] = []
        let paragraphs: [String] = randomArticle.body.split(with: Strings.paraSeparator)
        
        let randomParaIndex = (0..<paragraphs.count).randomElement()!
        
        for i in 0..<paragraphs.count {
            
            if i != randomParaIndex {
                continue
            }
            
            let readingPractice = ReadingPractice(articleAndParaIds: [randomArticle.id, i])
            
            let para = paragraphs[i]
            let splits = para.split(with: Strings.textAndMeaningSeparator)
            let text = splits[0]
            var meaning: String = ""
            if splits.count == 2 {
                meaning = splits[1]
            }
            
            readingPracticeList.append(
                ReadingPracticeItem(practice: readingPractice, text: text, meaning: meaning)
            )
        }
        return readingPracticeList
    }
}

struct TranslationPracticeProducer {
    
    var articles: [Article]
    
    struct TranslationPracticeItem {
        
        var practice: TranslationPractice
        var textToTranslate: String
        var textMeaning: String
        
    }
    
    func make() -> [TranslationPracticeItem] {
        // Randomly choose an article.
        guard let randomArticle = articles.randomElement() else {
            return []
        }
        
        // TODO: - Assure that the article is parallel.
        
        var translationPracticeList: [TranslationPracticeItem] = []
        let paragraphs: [String] = randomArticle.body.split(with: Strings.paraSeparator)
        
        let randomParaIndex = (0..<paragraphs.count).randomElement()!
        
        for i in 0..<paragraphs.count {
            
            if i != randomParaIndex {
                continue
            }
            
            let direction = UInt.random(in: 0...1)
            
            let translationPractice = TranslationPractice(
                articleAndParaIds: [randomArticle.id, i],
                direction: direction
            )
            
            let para = paragraphs[i]
            let textAndMeaning = para.split(with: Strings.textAndMeaningSeparator)
            if textAndMeaning.count != 2 {  // No meaning provided.
                continue
            }
            let text = textAndMeaning[0]
            let meaning = textAndMeaning[1]

            let textToTranslate: String!
            let textMeaning: String!
            if direction == 0 {
                textToTranslate = text
                textMeaning = meaning
            } else {
                textToTranslate = meaning
                textMeaning = text
            }
            translationPracticeList.append(
                TranslationPracticeItem(practice: translationPractice, textToTranslate: textToTranslate, textMeaning: textMeaning)
            )
        }
        
        if translationPracticeList.count == 0 {
            // TODO: - use translation apis later?
            return make()
        }
        
        return translationPracticeList
    }
}

enum PracticeStatus: UInt {
    case beforeAnswering = 0  // Before selection or filling in.
    case afterAnswering = 1  // After selection or filling in, but the done button has not been tapped.
    case finished = 2  // The done button has been tapped.
}
