//
//  WordCardEntry.swift
//  Polyglot
//
//  Created by Sola on 2023/9/10.
//  Copyright © 2023 Sola. All rights reserved.
//

import Foundation

struct ContentCard: Codable {
    
    enum ContentSource: Codable {
        case articles
        case chatgpt
    }
    
    var id: String
    var cDate: Date  // Creation date.
    
    var date: Date  // The date to display.
    var lang: String
    
    var words: [String]  // Texts of the words.
    var meanings: [String]  // Meanings of the words.
    var pronunciations: [String]  // Accented pronunciations.
    
    var content: String
    var contentSource: ContentCard.ContentSource
    
    init(
        date: Date, lang: String,
        words: [String], meanings: [String], pronunciations: [String],
        content: String, contentSource: ContentCard.ContentSource
    ) {
        
        self.id = UUID().uuidString
        self.cDate = Date()
        
        self.date = date
        self.lang = lang
        
        self.words = words
        self.meanings = meanings
        self.pronunciations = pronunciations
        
        self.content = content
        self.contentSource = contentSource
    }
    
}

extension ContentCard {
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case cDate
        
        case date
        case lang
        
        case words
        case meanings
        case pronunciations
        
        case content
        case contentSource
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(cDate, forKey: .cDate)
        
        try container.encode(date, forKey: .date)
        try container.encode(lang, forKey: .lang)
        
        try container.encode(words, forKey: .words)
        try container.encode(meanings, forKey: .meanings)
        try container.encode(pronunciations, forKey: .pronunciations)
        
        try container.encode(content, forKey: .content)
        try container.encode(contentSource, forKey: .contentSource)
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
            cDate = Date()
        }
        
        date = try values.decode(Date.self, forKey: .date)
        lang = try values.decode(String.self, forKey: .lang)
        
        words = try values.decode([String].self, forKey: .words)
        meanings = try values.decode([String].self, forKey: .meanings)
        pronunciations = try values.decode([String].self, forKey: .pronunciations)
        
        content = try values.decode(String.self, forKey: .content)
        contentSource = try values.decode(ContentSource.self, forKey: .contentSource)
    }
}

extension ContentCard {
    
    // MARK: - IO
    
    static func fileName(for lang: String) -> String {
        return "contentCards.\(lang).json"
    }
    
    static func load(for lang: String) -> [ContentCard] {
        do {
            let entries = try readSequenceDataFromJson(
                fileName: ContentCard.fileName(for: lang),
                type: ContentCard.self
            ) as! [ContentCard]
            return entries
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ contentCards: inout [ContentCard], for lang: String) {
        do {
            try writeSequenceDataFromJson(
                fileName: ContentCard.fileName(for: lang),
                data: contentCards
            )
        } catch {
            print(error)
            exit(1)
        }
    }
}

extension ContentCard {
    
    static func metaDataFileName(for lang: String) -> String {
        return "contentCards.meta.\(lang).json"
    }
    
    static func loadMetaData(for lang: String) -> [String: String] {
        do {
            let metaData = try readMappingDataFromJson(
                fileName: ContentCard.metaDataFileName(for: lang),
                keyType: String.self,
                valType: String.self
            ) as! [String:String]
            return metaData
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func saveMetaData(_ metaData: inout [String:String], for lang: String) {
        do {
            try writeMappingDataFromJson(
                fileName: ContentCard.metaDataFileName(for: lang),
                data: metaData
            )
        } catch {
            print(error)
            exit(1)
        }
    }
}
	
extension ContentCard {
    
    static func loadSamples(for lang: String) -> [ContentCard] {
        return [
            ContentCard(
                date: Date(),
                lang: lang,
                words: ["This", "a word"],
                meanings: ["这个", "一个单词"],
                pronunciations: ["this", "a word"],
                content: "This is a word.",
                contentSource: .chatgpt
            ),
            ContentCard(
                date: Date(timeInterval: 3600, since: Date()),
                lang: lang,
                words: ["a bottle of", "water"],
                meanings: ["一瓶", "水"],
                pronunciations: ["a bottle of", "wota"],
                content: "There's a bottle of water.",
                contentSource: .chatgpt
            ),
            ContentCard(
                date: Date(timeInterval: 3600 * 2, since: Date()),
                lang: lang,
                words: ["a bottle of", "water"],
                meanings: ["一瓶", "水"],
                pronunciations: ["a bottle of", "water"],
                content: "There's a bottle of water.",
                contentSource: .chatgpt
            )
        ]
    }
    
}
