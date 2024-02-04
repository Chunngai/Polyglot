//
//  WordCardEntry.swift
//  Polyglot
//
//  Created by Sola on 2023/9/10.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

typealias ContentCardsHour = Int
typealias ContentCardsLang = String

typealias OldContentCardsHour = String

struct ContentCards {
    
    struct WordEntry: Codable {
        var isNewWord: Bool?
        var text: String?
        var meaning: String?
        var pronunciation: String?
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
    
    var dateString: String
    
    var words: [ContentCardsLang: [WordEntry]]
    var sentences: [ContentCardsHour: [ContentCardsLang: SentenceEntry]]
    var paragraphs: [ContentCardsHour: [ContentCardsLang: ParagraphEntry]]
    
}

extension ContentCards {
    
    struct OldWordEntry: Codable {
        var text: String?
        var meaning: String?
        var pronunciation: String?
    }
    
    struct OldContentCardsWords: Codable {
        var new_word: WordEntry?
        var words_to_review: [WordEntry]?
    }
    
}

extension ContentCards: Codable {
    
    enum CodingKeys: String, CodingKey {
        case dateString
        case words = "words"
        case sentences = "sentences"
        case paragraphs = "paragraphs"
        
        // Old keys.
        
        case date
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(dateString, forKey: .dateString)
        
        try container.encode(words, forKey: .words)
        try container.encode(sentences, forKey: .sentences)
        try container.encode(paragraphs, forKey: .paragraphs)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            dateString = try values.decode(String.self, forKey: .dateString)
        } catch {
            dateString = try values.decode(String.self, forKey: .date)
        }
        
        do {
            words = try values.decode([ContentCardsLang: [WordEntry]].self, forKey: .words)
        } catch {
            let oldVersionWords = try values.decode([ContentCardsLang: OldContentCardsWords].self, forKey: .words)
            
            words = [:]
            for (lang, words_) in oldVersionWords {
                self.words[lang] = [WordEntry(
                    isNewWord: true,
                    text: words_.new_word!.text,
                    meaning: words_.new_word!.meaning,
                    pronunciation: words_.new_word!.pronunciation
                )]
                for word in words_.words_to_review! {
                    self.words[lang]!.append(WordEntry(
                        isNewWord: false,
                        text: word.text,
                        meaning: word.meaning,
                        pronunciation: word.pronunciation
                    ))
                }
            }
        }
        
        do {
            sentences = try values.decode([ContentCardsHour: [ContentCardsLang: SentenceEntry]].self, forKey: .sentences)
        } catch {
            let oldVersionSentences = try values.decode([ContentCardsLang: [OldContentCardsHour: SentenceEntry]].self, forKey: .sentences)
            
            sentences = [:]
            for (lang, hour2sentenceEntry) in oldVersionSentences {
                for (hourString, sentenceEntry) in hour2sentenceEntry {
                    let hour = Int(hourString)!
                    if !sentences.keys.contains(hour) {
                        sentences[hour] = [:]
                    }
                    sentences[hour]![lang] = sentenceEntry
                }
            }
        }
        
        do {
            paragraphs = try values.decode([ContentCardsHour: [ContentCardsLang: ParagraphEntry]].self, forKey: .paragraphs)
        } catch {
            let oldVersionParagraphs = try values.decode([ContentCardsLang: [OldContentCardsHour: ParagraphEntry]].self, forKey: .paragraphs)
            
            paragraphs = [:]
            for (lang, hour2paragraphEntry) in oldVersionParagraphs {
                for (hourString, paragraphEntry) in hour2paragraphEntry {
                    let hour = Int(hourString)!
                    if !paragraphs.keys.contains(hour) {
                        paragraphs[hour] = [:]
                    }
                    paragraphs[hour]![lang] = paragraphEntry
                }
            }
        }
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
                return ContentCards(dateString: "", words: [:], sentences: [:], paragraphs: [:])
            }
        } catch {
            print(error)
            return ContentCards(dateString: "", words: [:], sentences: [:], paragraphs: [:])
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
    
    static func fetchAndSave(completion: @escaping (ContentCards) -> Void) {
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
    static let hourFormat: String = "HH"
    
}
