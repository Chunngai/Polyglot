//
//  ReadingPractice.swift
//  Polyglot
//
//  Created by Sola on 2023/1/6.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ReadingPractice: Practice {
    
    var id: String
    var cDate: Date
    
    var articleId: String
    var paragraphId: String
        
    init(articleId: String, paragraphId: String) {
        
        self.id = UUID().uuidString
        self.cDate = Date()
        
        self.articleId = articleId
        self.paragraphId = paragraphId
    }
}

extension ReadingPractice: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case cDate
        
        case articleId
        case paragraphId
        
        // Old vars.
        
        case creationDate  // cDate.
        
        case articleAndParaIds  // articleId and paragraphId.
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(cDate, forKey: .cDate)
        
        try container.encode(articleId, forKey: .articleId)
        try container.encode(paragraphId, forKey: .paragraphId)
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
            articleId = try values.decode(String.self, forKey: .articleId)
            paragraphId = try values.decode(String.self, forKey: .paragraphId)
        } catch {
            articleId = ""
            paragraphId = ""
        }
    }
}
