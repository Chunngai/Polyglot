//
//  WordPractice.swift
//  Polyglot
//
//  Created by Sola on 2023/1/6.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct WordPractice: Practice {
    
    var id: String
    var cDate: Date
        
    var practiceType: PracticeType
    var wordId: String  // Word to practice.
    
    // For selection practices.
    var selectionWordsIds: [String]?
    // For context practices.
    var articleId: String?
    var paragraphId: String?

    // 0: text -> meaning.
    // 1: meaning -> text.
    var direction: UInt
    
    // Selected word id or filled answer.
    var answer: String?
    
    init(practiceType: WordPractice.PracticeType, wordId: String, selectionWordsIds: [String]? = nil, articleId: String? = nil, paragraphId: String? = nil, direction: UInt, answer: String? = nil) {
        
        self.id = UUID().uuidString
        self.cDate = Date()
        
        self.practiceType = practiceType
        self.wordId = wordId
        
        self.selectionWordsIds = selectionWordsIds
        self.articleId = articleId
        self.paragraphId = paragraphId
        
        self.direction = direction
        
        self.answer = answer
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
        
        case answer
        
        // Old vars.
        
        case creationDate  // cDate
        
        case type  // practiceType.
        
        case articleAndSentenceIds  // articleId, paragraphId
        
        case selectedWordId  // answer
        case filledText  // answer
        
        case typedAnswer  // filledText->answer
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
        
        try container.encode(answer, forKey: .answer)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try values.decode(String.self, forKey: .id)
        } catch {
            id = UUID().uuidString
        }
        
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
        
        do {
            wordId = try values.decode(String.self, forKey: .wordId)
        } catch {
            wordId = ""
        }
        
        do {
            selectionWordsIds = try values.decode([String]?.self, forKey: .selectionWordsIds)
        } catch {
            selectionWordsIds = ["", "", ""]
        }
        
        do {
            articleId = try values.decode(String.self, forKey: .articleId)
            paragraphId = try values.decode(String.self, forKey: .paragraphId)
        } catch {
            articleId = ""
            paragraphId = ""
        }
        
        direction = try values.decode(UInt.self, forKey: .direction)
        
        do {
            answer = try values.decode(String?.self, forKey: .answer)
        } catch {
            answer = ""
        }
    }
}

extension WordPractice {
    
    // MARK: - IO
    
    static var fileName: String {
        return "wordPractices.\(Variables.lang).json"
    }
    
    static func load() -> [WordPractice] {
        do {
            let wordPractices = try readSequenceDataFromJson(fileName: WordPractice.fileName, type: WordPractice.self) as! [WordPractice]
            return wordPractices
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ wordPractices: inout [WordPractice]) {
        do {
            try writeSequenceDataFromJson(fileName: WordPractice.fileName, data: wordPractices)
        } catch {
            print(error)
            exit(1)
        }
    }
}
