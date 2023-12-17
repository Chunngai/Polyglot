//
//  WordCardEntry.swift
//  Polyglot
//
//  Created by Sola on 2023/9/10.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

typealias ContentCardsLang = String
typealias ContentCardsHour = String

struct ContentCards: Codable {
    
    struct WordEntry: Codable {
        var text: String?
        var meaning: String?
        var pronunciation: String?
    }
    
    struct ContentCardsWords: Codable {
        var new_word: WordEntry?
        var words_to_review: [WordEntry]?
    }
    
    struct SentenceEntry: Codable {
        var word: WordEntry?
        var content: String?
        var source: String?
    }
    
    struct ParagraphEntry: Codable {
        var content: String?
        var source: String?
    }
    
    var date: String
    
    var words: [ContentCardsLang: ContentCardsWords]  // lang: wordEntry
    var sentences: [ContentCardsLang: [ContentCardsHour: SentenceEntry]]  // lang: [hour: sentenceEntry]
    var paragraphs: [ContentCardsLang: [ContentCardsHour: ParagraphEntry]]  // lang: [hour: paragraphEntry]

    enum CodingKeys: String, CodingKey {
        case date
        case words = "words"
        case sentences = "sentences"
        case paragraphs = "paragraphs"
    }
}

extension ContentCards {
    
    // MARK: - IO
    
    static let fileName: String = "contentCards.json"
    
    static func load() -> ContentCards {
        do {
            if let contentCards = try readDataFromJson(
                fileName: ContentCards.fileName,
                type: ContentCards.self
            ) as? ContentCards {
                return contentCards
            } else {
                return ContentCards(date: "", words: [:], sentences: [:], paragraphs: [:])
            }
        } catch {
            print(error)
            return ContentCards(date: "", words: [:], sentences: [:], paragraphs: [:])
        }
    }
    
    static func save(_ contentCards: inout ContentCards) {
        do {
            try writeDataToJson(
                fileName: ContentCards.fileName,
                data: contentCards
            )
        } catch {
            print(error)
            exit(1)
        }
    }
    
}

extension ContentCards {
    
    static func fetch(completion: @escaping (ContentCards) -> Void) {
        let json: [String: Any] = [
            "date": Date().repr(of: ContentCards.dateFormat)
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        
        let url = URL(string: "http://4o51096o21.zicp.vip/content")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(String(describing: jsonData.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data, error == nil {
                if var contentCards = try? JSONDecoder().decode(ContentCards.self, from: data) {
                    completion(contentCards)
                    ContentCards.save(&contentCards)
                }
            }
            
            if error != nil {
                if let errDescription = error?.localizedDescription {
                    print(errDescription)
                } else {
                    print("error")
                }
            }
        }
        task.resume()
    }
    
}

extension ContentCards {
    
    static let dateFormat: String = "yyMMdd"
    
}
