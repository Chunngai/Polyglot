//
//  TextSource.swift
//  Polyglot
//
//  Created by Ho on 2/17/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation

enum TextSource: Codable, Equatable {
    case article(
        articleId: String,
        paragraphId: String?,
        sentenceId: Int?
    )
    case chatGpt
    case none
}

extension TextSource {
    
    private enum CodingKeys: String, CodingKey {
        case type
        case articleId
        case paragraphId
        case sentenceId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .article(let articleId, let paragraphId, let sentenceId):
            try container.encode("article", forKey: .type)
            try container.encode(articleId, forKey: .articleId)
            try container.encode(paragraphId, forKey: .paragraphId)
            try container.encode(sentenceId, forKey: .sentenceId)
        case .chatGpt:
            try container.encode("chatGpt", forKey: .type)
        case .none:
            try container.encode("none", forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "article":
            let articleId = try container.decode(String.self, forKey: .articleId)
            let paragraphId = try container.decode(String?.self, forKey: .paragraphId)
            let sentenceId = try container.decode(Int?.self, forKey: .sentenceId)
            self = .article(
                articleId: articleId,
                paragraphId: paragraphId,
                sentenceId: sentenceId
            )
        case "chatGpt":
            self = .chatGpt
        case "none":
            self = .none
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
    }
    
}
