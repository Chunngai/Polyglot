//
//  Word.swift
//  Polyglot
//
//  Created by Sola on 2022/12/26.
//  Copyright © 2022 Sola. All rights reserved.
//

import Foundation

struct Token: Codable {
    
    var text: String
    var baseForm: String
    var pronunciation: String
    var accentLoc: Int?
    
    init(text: String, baseForm: String, pronunciation: String, accentLoc: Int?) {
        
        self.text = text.lowercased().strip()
        self.baseForm = baseForm.lowercased().strip()
        self.pronunciation = pronunciation.lowercased().strip()
        self.accentLoc = accentLoc
        
    }
    
}

struct Word {
    
    var id: String
    var cDate: Date  // Creation date.
    var mDate: Date  // Modification date.
    
    var text: String
    var tokens: [Token]?
    
    var meaning: String
    
    var note: String?
    
    init(cDate: Date = Date(), text: String, tokens: [Token]? = nil, meaning: String, note: String? = nil) {
        
        self.id = UUID().uuidString
        self.cDate = cDate
        self.mDate = cDate
        
        self.text = text.lowercased().strip()
        self.tokens = tokens
        
        self.meaning = meaning.lowercased().strip()
        
        self.note = note
    }
    
    mutating func update(newText: String? = nil, newTokens: [Token]? = nil, newMeaning: String? = nil, newNote: String? = nil) {
        
        if let newText = newText {
            self.text = newText.lowercased().strip()
        }
        
        if let newTokens = newTokens {
            self.tokens = newTokens
        }
        
        if let newMeaning = newMeaning {
            self.meaning = newMeaning.lowercased().strip()
        }
        
        if let newNote = newNote {
            self.note = newNote
        }
        
        self.mDate = Date()
    }
}

extension Word: Codable {
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case cDate
        case mDate
        
        case text
        case tokens
        
        case meaning
        
        case note
        
        // Old vars.
        
        case creationDate  // cDate.
        case modificationDate  // mDate.
        
        case word  // text.
        
        case groupNote  // note
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(cDate, forKey: .cDate)
        try container.encode(mDate, forKey: .mDate)
        
        try container.encode(text, forKey: .text)
        try container.encode(tokens, forKey: .tokens)
        
        try container.encode(meaning, forKey: .meaning)
        
        try container.encode(note, forKey: .note)
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
            mDate = try values.decode(Date.self, forKey: .mDate)
        } catch {
            mDate = try values.decode(Date.self, forKey: .modificationDate)
        }
        
        do {
            text = try values.decode(String.self, forKey: .text)
        } catch {
            text = try values.decode(String.self, forKey: .word)
        }
        
        do {
            tokens = try values.decode([Token].self, forKey: .tokens)
        } catch {
            tokens = nil
        }
        
        meaning = try values.decode(String.self, forKey: .meaning)
        
        do {
            note = try values.decode(String?.self, forKey: .note)
        } catch {
            note = try values.decode(String?.self, forKey: .groupNote)
        }
    }
}

extension Word {
    
    // MARK: - IO
    
    static var fileName: String {
        return "words.\(Variables.lang).json"
    }
    
    static func load() -> [Word] {
        do {
            let words = try readSequenceDataFromJson(fileName: Word.fileName, type: Word.self) as! [Word]
            return words
        } catch {
            print(error)
            exit(1)
        }
    }
    
    static func save(_ words: inout [Word]) {
        do {
            try writeSequenceDataFromJson(fileName: Word.fileName, data: words)
        } catch {
            print(error)
            exit(1)
        }
    }
}

extension Word {
    
    static var samples: [Word] = [
        Word(cDate: Date(), text: "中間試験", meaning: "期中考"),
        Word(cDate: Date(), text: "秘密兵器", meaning: "秘密兵器"),
        Word(cDate: Date(), text: "出題範囲", meaning: "出题范围"),
        Word(cDate: Date(), text: "図工", meaning: "手工"),
        Word(cDate: Date(), text: "戦争から立ち直る", meaning: "从战争中重振"),
        Word(cDate: Date(), text: "作戦する", meaning: "行动"),
        Word(cDate: Date(), text: "水道水", meaning: "自来水"),
        Word(cDate: Date(), text: "辺鄙な", meaning: "偏僻的"),
        Word(cDate: Date(timeInterval: 300000, since: Date()), text: "作戦する", meaning: "行动"),
        Word(cDate: Date(timeInterval: 300000, since: Date()), text: "水道水", meaning: "自来水"),
        Word(cDate: Date(timeInterval: 300000, since: Date()), text: "辺鄙な", meaning: "偏僻的")
    ]
    
}
