//
//  TranslationPractice.swift
//  Polyglot
//
//  Created by Sola on 2023/1/6.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct TranslationPractice: Practice {
    
    var id: Int
    var creationDate: Date
    
    var articleAndParaIds: [Int]  // [article id, para id].
    
    var direction: UInt  // 0: article -> meaning. 1: meaning -> article.
    
    init(articleAndParaIds: [Int], direction: UInt) {
        self.id = Date().hashValue
        self.creationDate = Date()
        
        self.articleAndParaIds = articleAndParaIds
        self.direction = direction
    }
}

extension TranslationPractice: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case creationDate
        case articleAndPractice
        case direction
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(articleAndParaIds, forKey: .articleAndPractice)
        try container.encode(direction, forKey: .direction)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(Int.self, forKey: .id)
        creationDate = try values.decode(Date.self, forKey: .creationDate)
        articleAndParaIds = try values.decode([Int].self, forKey: .articleAndPractice)
        direction = try values.decode(UInt.self, forKey: .direction)
    }
}
