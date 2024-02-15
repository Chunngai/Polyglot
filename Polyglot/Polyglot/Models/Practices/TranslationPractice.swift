////
////  TranslationPractice.swift
////  Polyglot
////
////  Created by Sola on 2023/1/6.
////  Copyright © 2023 Sola. All rights reserved.
////
//
//import Foundation
//
//struct TranslationPractice: Practice {
//    
//    var id: String
//    var cDate: Date
//    
//    var articleId: String
//    var paragraphId: String
//    
//    // 0: text -> meaning.
//    // 1: meaning -> text.
//    var direction: PracticeDirection
//    
//    init(articleId: String, paragraphId: String, direction: PracticeDirection) {
//        
//        self.id = UUID().uuidString
//        self.cDate = Date()
//        
//        self.articleId = articleId
//        self.paragraphId = paragraphId
//        
//        self.direction = direction
//    }
//}
//
//extension TranslationPractice: Codable {
//    
//    enum CodingKeys: String, CodingKey {
//        
//        case id
//        case cDate
//        
//        case articleId
//        case paragraphId
//        
//        case direction
//
//        // Old vars.
//        
//        case creationDate  // cDate
//        
//        case articleAndParaIds  // articleId and paragraphId.
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        
//        try container.encode(id, forKey: .id)
//        try container.encode(cDate, forKey: .cDate)
//        
//        try container.encode(articleId, forKey: .articleId)
//        try container.encode(paragraphId, forKey: .paragraphId)
//        
//        try container.encode(direction, forKey: .direction)
//    }
//    
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        
//        do {
//            id = try values.decode(String.self, forKey: .id)
//        } catch {
//            id = UUID().uuidString
//        }
//        
//        do {
//            cDate = try values.decode(Date.self, forKey: .cDate)
//        } catch {
//            cDate = try values.decode(Date.self, forKey: .creationDate)
//        }
//        
//        do {
//            articleId = try values.decode(String.self, forKey: .articleId)
//            paragraphId = try values.decode(String.self, forKey: .paragraphId)
//        } catch {
//            articleId = ""
//            paragraphId = ""
//        }
//        
//        do {
//            direction = try values.decode(PracticeDirection.self, forKey: .direction)
//        } catch {
//            let _direction = try values.decode(UInt.self, forKey: .direction)
//            direction = PracticeDirection(rawValue: _direction) ?? PracticeDirection(rawValue: 0)!
//        }
//    }
//}
