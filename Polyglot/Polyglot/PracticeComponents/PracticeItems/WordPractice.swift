//
//  WordPractice.swift
//  Polyglot
//
//  Created by Sola on 2023/1/6.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation
import NaturalLanguage

class WordPractice: BasePractice, Codable {
    
    var id: UUID = UUID()
    var cDate: Date = Date()
    var practiceType: PracticeType
    var word: String  // Word to practice.
    var query: String
    var key: String
    var prompt: String
    var choices: [String]?
    var context: String?
    var reorderingWordList: [String]?
    var reorderingTextTranslation: String?
    var imageUrl: String?
    var articleId: String?
    var paragraphId: String?
    // 0: text -> meaning.
    // 1: meaning -> text.
    // 2: text.
    var direction: PracticeDirection
    var periodIndex: Int?
    // correct/incorrect/partiallyCorrect
    var correctness: Correctness!
    var verbAspectAnnotations: [VerbAspectAnnotation]
    var nounCaseAnnotations: [NounCaseAnnotation]

    init(
        practiceType: WordPractice.PracticeType,
        word: String,
        query: String,
        key: String,
        prompt: String,
        choices: [String]? = nil,
        context: String? = nil,
        reorderingWordList: [String]? = nil,
        reorderingTextTranslation: String? = nil,
        imageUrl: String? = nil,
        articleId: String? = nil,
        paragraphId: String? = nil,
        direction: PracticeDirection,
        periodIndex: Int? = nil,
        correctness: Correctness? = nil,
        verbAspectAnnotations: [VerbAspectAnnotation] = [],
        nounCaseAnnotations: [NounCaseAnnotation] = []
    ) {

        self.practiceType = practiceType
        self.word = word
        self.query = query
        self.key = key
        self.prompt = prompt
        self.choices = choices
        self.context = context
        self.reorderingWordList = reorderingWordList
        self.reorderingTextTranslation = reorderingTextTranslation
        self.imageUrl = imageUrl
        self.articleId = articleId
        self.paragraphId = paragraphId
        self.direction = direction
        self.periodIndex = periodIndex
        self.correctness = correctness
        self.verbAspectAnnotations = verbAspectAnnotations
        self.nounCaseAnnotations = nounCaseAnnotations

    }
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case cDate
        case practiceType
        case word
        case query
        case key
        case prompt
        case choices
        case context
        case reorderingWordList
        case reorderingTextTranslation
        case imageUrl
        case articleId
        case paragraphId
        case direction
        case periodIndex
        case correctness
        case verbAspectAnnotations
        case nounCaseAnnotations

    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(cDate, forKey: .cDate)
        try container.encode(practiceType, forKey: .practiceType)
        try container.encode(word, forKey: .word)
        try container.encode(query, forKey: .query)
        try container.encode(key, forKey: .key)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(choices, forKey: .choices)
        try container.encode(context, forKey: .context)
        try container.encode(reorderingWordList, forKey: .reorderingWordList)
        try container.encode(reorderingTextTranslation, forKey: .reorderingTextTranslation)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(articleId, forKey: .articleId)
        try container.encode(paragraphId, forKey: .paragraphId)
        try container.encode(direction, forKey: .direction)
        try container.encodeIfPresent(periodIndex, forKey: .periodIndex)
        try container.encode(correctness, forKey: .correctness)
        try container.encode(verbAspectAnnotations, forKey: .verbAspectAnnotations)
        try container.encode(nounCaseAnnotations, forKey: .nounCaseAnnotations)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        cDate = try values.decode(Date.self, forKey: .cDate)
        practiceType = try values.decode(WordPractice.PracticeType.self, forKey: .practiceType)
        word = try values.decode(String.self, forKey: .word)
        query = try values.decode(String.self, forKey: .query)
        key = try values.decode(String.self, forKey: .key)
        prompt = try values.decode(String.self, forKey: .prompt)
        choices = try values.decode([String]?.self, forKey: .choices)
        context = try values.decode(String?.self, forKey: .context)
        reorderingWordList = try values.decode([String]?.self, forKey: .reorderingWordList)
        reorderingTextTranslation = try values.decode(String?.self, forKey: .reorderingTextTranslation)
        imageUrl = try values.decode(String?.self, forKey: .imageUrl)
        articleId = try values.decode(String?.self, forKey: .articleId)
        paragraphId = try values.decode(String?.self, forKey: .paragraphId)
        direction = try values.decode(PracticeDirection.self, forKey: .direction)
        periodIndex = try values.decodeIfPresent(Int.self, forKey: .periodIndex)
        correctness = try values.decode(Correctness?.self, forKey: .correctness)
        do {
            verbAspectAnnotations = try values.decode([VerbAspectAnnotation].self, forKey: .verbAspectAnnotations)
        } catch {
            verbAspectAnnotations = []
        }
        do {
            nounCaseAnnotations = try values.decode([NounCaseAnnotation].self, forKey: .nounCaseAnnotations)
        } catch {
            nounCaseAnnotations = []
        }

    }
    
    convenience init(from another: WordPractice) {
        self.init(
            practiceType: another.practiceType,
            word: another.word,
            query: another.query,
            key: another.key,
            prompt: another.prompt,
            choices: another.choices,
            context: another.context,
            reorderingWordList: another.reorderingWordList,
            reorderingTextTranslation: another.reorderingTextTranslation,
            imageUrl: another.imageUrl,
            articleId: another.articleId,
            paragraphId: another.paragraphId,
            direction: another.direction,
            periodIndex: another.periodIndex,
            correctness: another.correctness,
            verbAspectAnnotations: another.verbAspectAnnotations,
            nounCaseAnnotations: another.nounCaseAnnotations
        )
    }
    
}

extension WordPractice {
    
    enum PracticeType: UInt, Codable, CaseIterable {

        case meaningSelection
        case meaningFilling
        case contextSelection
        case accentSelection
        case reordering
        case imageSelection
        case imageFilling
        case phraseConstruction

    }

    enum PracticeDirection: UInt, Codable {
        
        case textToMeaning = 0
        case meaningToText = 1
        case text = 2
        
    }
    
}

extension WordPractice {
    
    enum Correctness: UInt, Codable {

        case incorrect
        case correct
        case partiallyCorrect  // E.g., for meaning filling.
        
    }
    
    var tokenizer: NLTokenizer {
        
        let lang: LangCode = {
            switch direction {
            case .textToMeaning: return LangCode.currentLanguage.configs.languageForTranslation
            case .meaningToText: return LangCode.currentLanguage
            case .text: return LangCode.currentLanguage
            }
        }()
        
        return lang.wordTokenizer
        
    }
    
    func checkCorrectness(answer: String) {
        
        // Do not normalize for accent practices,
        // or the accent mark will be removed.
        let shouldIgnoreCaseAndAccent = (
            practiceType == .meaningFilling
            || practiceType == .imageFilling
        )
        
        let key = self.key.normalized(
            caseInsensitive: shouldIgnoreCaseAndAccent,
            diacriticInsensitive: shouldIgnoreCaseAndAccent
        )
        let answer = answer.normalized(
            caseInsensitive: shouldIgnoreCaseAndAccent,
            diacriticInsensitive: shouldIgnoreCaseAndAccent
        )
        
        let keyComponents = key.tokenized(with: tokenizer)
        let answerComponents = answer.tokenized(with: tokenizer)
        
        if keyComponents == answerComponents {
            // Totally correct, including word order.
            correctness = .correct
        } else {
            if !Set(keyComponents).intersection(Set(answerComponents)).isEmpty {
                correctness = .partiallyCorrect
            } else {
                correctness = .incorrect
            }
        }
    }
    
}
