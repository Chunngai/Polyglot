//
//  HistoryRecord.swift
//  Polyglot
//
//  Created by Sola on 2022/12/29.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

struct HistoryRecord {
    
    var id: Int
    var creationDate: Date
    
    var practice: Practice
    
    init(practice: Practice) {
        self.id = Date().hashValue
        self.creationDate = Date()
        
        self.practice = practice
    }
    
}

extension HistoryRecord: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case creationDate
        case practice
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(creationDate, forKey: .creationDate)
        
        if let practice = practice as? WordPractice {
            try container.encode(practice, forKey: .practice)
        } else if let practice = practice as? ReadingPractice {
            try container.encode(practice, forKey: .practice)
        } else if let practice = practice as? TranslationPractice {
            try container.encode(practice, forKey: .practice)
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(Int.self, forKey: .id)
        creationDate = try values.decode(Date.self, forKey: .creationDate)
        
        if let practice = try? values.decode(WordPractice.self, forKey: .practice) {
            self.practice = practice
        } else if let practice = try? values.decode(ReadingPractice.self, forKey: .practice) {
            self.practice = practice
        } else if let practice = try? values.decode(TranslationPractice.self, forKey: .practice) {
            self.practice = practice
        } else {
            // Default value.
            self.practice = TranslationPractice(articleId: 0, paragraphId: "", direction: 0)
        }
    }
}

extension HistoryRecord {
    
    // MARK: - IO
    
    static let fileName: String = "history.json"
    
    static func load() -> [HistoryRecord] {
        do {
            let history = try readSequenceDataFromJson(fileName: HistoryRecord.fileName, type: HistoryRecord.self) as! [HistoryRecord]
            return history
        } catch {
            print(error)
            exit(1)
        }
    }
    static func save(_ history: inout [HistoryRecord]) {
        do {
            try writeSequenceDataFromJson(fileName: HistoryRecord.fileName, data: history)
        } catch {
            print(error)
            exit(1)
        }
    }
    
}

extension HistoryRecord {
    
//    static var samples: [HistoryRecord] = {
//        let wordSamples = Word.samples
//        let articleSamples = Article.samples
//        
//        return [
//            HistoryRecord(
//                practice: WordPractice(
//                    wordId: wordSamples[0].id,
//                    type: .meaningSelection,
//                    selectionWordsIds: (wordSamples[1].id, wordSamples[2].id, wordSamples[3].id),
//                    direction: 0,
//                    correctness: Correctness.correct
//                )
//            ),
//            HistoryRecord(practice: WordPractice(
//                wordId: wordSamples[2].id,
//                type: .meaningFilling,
//                direction: 0,
//                correctness: .incorrect
//            )),
//            HistoryRecord(practice: ReadingPractice(articleAndParaIds: (articleSamples[0].id, 1))
//            )
//        ]
//    }()
    
}
