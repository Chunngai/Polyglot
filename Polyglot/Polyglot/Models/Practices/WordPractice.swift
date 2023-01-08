//
//  WordPractice.swift
//  Polyglot
//
//  Created by Sola on 2023/1/6.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct WordPractice: Practice {
    
    var id: Int
    var cDate: Date
        
    var practiceType: PracticeType
    var wordId: Int  // Word to practice.
    
    // For selection practices.
    var selectionWordsIds: [Int]?
    // For context practices.
    var articleId: Int?
    var paragraphId: String?

    // 0: text -> meaning.
    // 1: meaning -> text.
    var direction: UInt
    
    // For selection practices.
    var selectedWordId: Int?
    // For filling practices.
    var filledText: String?
    
    init(practiceType: WordPractice.PracticeType, wordId: Int, selectionWordsIds: [Int]? = nil, articleId: Int? = nil, paragraphId: String? = nil, direction: UInt, selectedWordId: Int? = nil, filledText: String? = nil) {
        
        self.id = Date().hashValue
        self.cDate = Date()
        
        self.practiceType = practiceType
        self.wordId = wordId
        
        self.selectionWordsIds = selectionWordsIds
        self.articleId = articleId
        self.paragraphId = paragraphId
        
        self.direction = direction
        
        self.selectedWordId = selectedWordId
        self.filledText = filledText
    }
}

extension WordPractice {
    
    enum PracticeType: Int, Codable {
        case meaningSelection
        case meaningFilling
        case contextSelection
    }
    
}

extension WordPractice: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case cDate
        
        case practiceType
        case wordId
        
        case selectionWordsIds
        case articleId
        case paragraphId
        
        case direction
        
        case selectedWordId
        case filledText
        
        // Old vars.
        
        case creationDate  // cDate
        
        case type  // practiceType.
        
        case articleAndSentenceIds  // articleId, paragraphId
        
        case typedAnswer  // filledText
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(cDate, forKey: .cDate)
        
        try container.encode(practiceType, forKey: .practiceType)
        try container.encode(wordId, forKey: .wordId)
        
        try container.encode(selectionWordsIds, forKey: .selectionWordsIds)
        try container.encode(articleId, forKey: .articleId)
        try container.encode(paragraphId, forKey: .paragraphId)
        
        try container.encode(direction, forKey: .direction)
        
        try container.encode(selectedWordId, forKey: .selectedWordId)
        try container.encode(filledText, forKey: .filledText)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(Int.self, forKey: .id)
        
        do {
            cDate = try values.decode(Date.self, forKey: .cDate)
        } catch {
            cDate = try values.decode(Date.self, forKey: .creationDate)
        }
        
        do {
            practiceType = try values.decode(WordPractice.PracticeType.self, forKey: .practiceType)
        } catch {
            practiceType = try values.decode(WordPractice.PracticeType.self, forKey: .type)
        }
        
        wordId = try values.decode(Int.self, forKey: .wordId)
        
        selectionWordsIds = try values.decode([Int]?.self, forKey: .selectionWordsIds)
        
        do {
            articleId = try values.decode(Int.self, forKey: .articleId)
            paragraphId = try values.decode(String.self, forKey: .paragraphId)
        } catch {
            let articleAndSentenceIds = try values.decode([Int]?.self, forKey: .articleAndSentenceIds)
            articleId = articleAndSentenceIds?[0]
            paragraphId = ""
        }
        
        direction = try values.decode(UInt.self, forKey: .direction)
        
        selectedWordId = try values.decode(Int?.self, forKey: .selectedWordId)
        
        do {
            filledText = try values.decode(String?.self, forKey: .filledText)
        } catch {
            filledText = try values.decode(String?.self, forKey: .typedAnswer)
        }
    }
}
