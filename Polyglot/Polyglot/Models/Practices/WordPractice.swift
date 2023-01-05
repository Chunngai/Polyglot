//
//  WordPractice.swift
//  Polyglot
//
//  Created by Sola on 2023/1/6.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct WordPractice: Practice {
    
    enum WordPracticeType: Int, Codable {
        case meaningSelection = 0
        case meaningFilling = 1
        case contextSelection = 2
    }
    
    var id: Int
    var creationDate: Date
        
    var wordId: Int  // Word to practice.
    var type: WordPracticeType
        
    var selectionWordsIds: [Int]?  // For meaning selection and context selection. [word1 id, word2 id, word3 id].
    var articleAndSentenceIds: [Int]?  // For context selection. [article id, sentence id].

    var direction: UInt  // Used for meaning selection and meaning filling. 0: word -> meaning. 1: meaning -> word.
    
    var selectedWordId: Int?  // Used for meaning selection and context selection.
    var typedAnswer: String?  // Used for meaning filling.
        
    init(id: Int, creationDate: Date, wordId: Int, type: WordPracticeType, selectionWordsIds: [Int]? = nil, contextId: [Int]? = nil, direction: UInt, selectedWordId: Int? = nil, typedAnswer: String? = nil) {
        self.id = id
        self.creationDate = creationDate
        
        self.wordId = wordId
        self.type = type
        self.selectionWordsIds = selectionWordsIds
        self.articleAndSentenceIds = contextId
        self.direction = direction
        
        self.selectedWordId = selectedWordId
        self.typedAnswer = typedAnswer
    }
    
    init(wordId: Int, type: WordPracticeType, selectionWordsIds: [Int]? = nil, contextId: [Int]? = nil, direction: UInt, selectedWordId: Int? = nil, typedAnswer: String? = nil) {
        let id = Date().hashValue
        let creationDate = Date()
        
        self.init(id: id, creationDate: creationDate, wordId: wordId, type: type, selectionWordsIds: selectionWordsIds, contextId: contextId, direction: direction, selectedWordId: selectedWordId, typedAnswer: typedAnswer)
    }
}

extension WordPractice: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case creationDate
        case wordId
        case type
        case selectionWordsIds
        case articleAndSentenceIds
        case direction
        case selectedWordId
        case typedAnswer
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(wordId, forKey: .wordId)
        try container.encode(type, forKey: .type)
        try container.encode(selectionWordsIds, forKey: .selectionWordsIds)
        try container.encode(articleAndSentenceIds, forKey: .articleAndSentenceIds)
        try container.encode(direction, forKey: .direction)
        try container.encode(selectedWordId, forKey: .selectedWordId)
        try container.encode(typedAnswer, forKey: .typedAnswer)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(Int.self, forKey: .id)
        creationDate = try values.decode(Date.self, forKey: .creationDate)
        wordId = try values.decode(Int.self, forKey: .wordId)
        type = try values.decode(WordPractice.WordPracticeType.self, forKey: .type)
        selectionWordsIds = try values.decode([Int]?.self, forKey: .selectionWordsIds)
        articleAndSentenceIds = try values.decode([Int]?.self, forKey: .articleAndSentenceIds)
        direction = try values.decode(UInt.self, forKey: .direction)
        selectedWordId = try values.decode(Int?.self, forKey: .selectedWordId)
        typedAnswer = try values.decode(String?.self, forKey: .typedAnswer)
    }
}
